import AVFoundation
import Observation
import UIKit
import Vision

/// Owns the camera session and turns each frame into a `PoseSample` with Vision's body pose model.
///
/// Nothing is written to disk and no frame leaves the phone. On a device without a usable camera
/// (including the Simulator) it falls back to a simulated body so the whole app can still be explored.
@Observable
final class BodyTracker: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    static var isCameraAvailable: Bool {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil
    }

    let session = AVCaptureSession()

    /// Latest sample, published on the main thread for SwiftUI.
    private(set) var sample: PoseSample = .empty
    private(set) var framing: Framing = Framing(problem: .noBody, coverage: 0)
    private(set) var isRunning = false
    private(set) var isSimulated = false
    private(set) var permissionDenied = false
    private(set) var errorMessage: String?

    /// Receives every processed sample. Engines hook in here.
    @ObservationIgnored var onSample: ((PoseSample) -> Void)?
    /// Demo mode only: the shape the simulated body should settle into.
    @ObservationIgnored var simulatedTarget: FigurePose = .mountain
    /// Demo mode only: whether the simulated body should stand side-on.
    @ObservationIgnored var simulatedFacing: CameraFacing = .front

    @ObservationIgnored private let queue = DispatchQueue(label: "asanafit.camera", qos: .userInitiated)
    @ObservationIgnored private let request = VNDetectHumanBodyPoseRequest()
    @ObservationIgnored private let output = AVCaptureVideoDataOutput()
    @ObservationIgnored private var isConfigured = false
    @ObservationIgnored private var lastProcessed: TimeInterval = 0
    @ObservationIgnored private var simulationTimer: Timer?
    @ObservationIgnored private var simulationStart: TimeInterval = 0
    /// Smoothed joints. Vision jitters a little frame to frame, and a held yoga pose should not flicker.
    @ObservationIgnored private var smoothed: [Joint: JointPoint] = [:]

    override init() {
        super.init()
    }

    // MARK: - Lifecycle

    func start() {
        guard !isRunning else { return }
        isRunning = true
        errorMessage = nil
        smoothed = [:]

        guard Self.isCameraAvailable else {
            startSimulation()
            return
        }
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndRun()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    guard self.isRunning else { return }
                    if granted {
                        self.configureAndRun()
                    } else {
                        self.permissionDenied = true
                        self.startSimulation()
                    }
                }
            }
        default:
            permissionDenied = true
            startSimulation()
        }
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        simulationTimer?.invalidate()
        simulationTimer = nil
        guard !isSimulated else { return }
        queue.async { [session] in
            if session.isRunning { session.stopRunning() }
        }
    }

    // MARK: - Camera

    private func configureAndRun() {
        isSimulated = false
        queue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configure()
            }
            guard self.isConfigured, !self.session.isRunning else { return }
            self.session.startRunning()
        }
    }

    private func configure() {
        session.beginConfiguration()
        session.sessionPreset = .hd1280x720

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.errorMessage = "Could not open the front camera."
                self.startSimulation()
            }
            return
        }
        session.addInput(input)

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        guard session.canAddOutput(output) else {
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.errorMessage = "Could not read frames from the camera."
                self.startSimulation()
            }
            return
        }
        session.addOutput(output)

        if let connection = output.connection(with: .video) {
            // Hand Vision an upright portrait frame so joint positions need no rotation.
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            // The preview is mirrored for a natural selfie view, but the frames Vision sees are not:
            // a mirrored body confuses its idea of which limb is left and which is right.
            if connection.isVideoMirroringSupported {
                connection.automaticallyAdjustsVideoMirroring = false
                connection.isVideoMirrored = false
            }
        }
        session.commitConfiguration()
        isConfigured = true
    }

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        let now = CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
        // Vision body pose at ~20 Hz is smooth enough to coach a held pose and much kinder to the battery.
        guard now - lastProcessed >= 1.0 / 21.0 else { return }
        lastProcessed = now

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let aspect = height > 0 ? Double(width) / Double(height) : 9.0 / 16.0

        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return
        }

        guard let observation = (request.results)?.first,
              let points = try? observation.recognizedPoints(.all) else {
            publish(PoseSample(timestamp: now, isTracked: false, joints: [:], aspect: aspect))
            return
        }

        var joints: [Joint: JointPoint] = [:]
        for joint in Joint.allCases {
            guard let found = points[joint.visionName], found.confidence > 0 else { continue }
            joints[joint] = JointPoint(position: found.location, confidence: Double(found.confidence))
        }
        publish(PoseSample(timestamp: now, isTracked: !joints.isEmpty, joints: smooth(joints), aspect: aspect))
    }

    /// Exponential smoothing, weighted by confidence so a briefly uncertain joint does not jump.
    private func smooth(_ joints: [Joint: JointPoint]) -> [Joint: JointPoint] {
        var result: [Joint: JointPoint] = [:]
        for joint in Joint.allCases {
            guard let fresh = joints[joint] else {
                smoothed[joint] = nil
                continue
            }
            guard let previous = smoothed[joint] else {
                smoothed[joint] = fresh
                result[joint] = fresh
                continue
            }
            let weight = 0.45 + 0.35 * fresh.confidence
            let blended = JointPoint(
                position: CGPoint(
                    x: previous.position.x + (fresh.position.x - previous.position.x) * weight,
                    y: previous.position.y + (fresh.position.y - previous.position.y) * weight
                ),
                confidence: previous.confidence + (fresh.confidence - previous.confidence) * 0.5
            )
            smoothed[joint] = blended
            result[joint] = blended
        }
        return result
    }

    private func publish(_ newSample: PoseSample) {
        DispatchQueue.main.async {
            guard self.isRunning else { return }
            self.sample = newSample
            self.framing = Framing.check(newSample)
            self.onSample?(newSample)
        }
    }

    // MARK: - Simulation (no camera)

    private func startSimulation() {
        isSimulated = true
        simulationStart = ProcessInfo.processInfo.systemUptime
        simulationTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0 / 20.0, repeats: true) { [weak self] _ in
            self?.simulateFrame()
        }
        RunLoop.main.add(timer, forMode: .common)
        simulationTimer = timer
    }

    /// Eases into the pose the session is asking for, then holds it with a little sway,
    /// so every asana can be completed hands-free in demo mode.
    private func simulateFrame() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = now - simulationStart
        // Three seconds moving in, twenty holding, three coming out: long enough for a
        // five-breath hold to finish without the demo body wandering off mid-pose.
        let cycle = elapsed.truncatingRemainder(dividingBy: 26)
        let settle: Double
        switch cycle {
        case ..<3: settle = cycle / 3
        case ..<23: settle = 1
        default: settle = max(0, 1 - (cycle - 23) / 3)
        }
        let pose = FigurePose.mountain.blended(to: simulatedTarget, amount: settle)
        publish(SkeletonBuilder.sample(pose, timestamp: now, jitter: 0.0015,
                                       narrow: simulatedFacing == .side))
    }
}
