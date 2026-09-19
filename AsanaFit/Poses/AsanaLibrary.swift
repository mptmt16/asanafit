import Foundation

/// Every posture the app can coach.
///
/// Two-sided poses are written for the **left** side, facing the camera's right when the
/// pose is judged side-on. `Asana.mirrored` produces the other side, cues and all.
///
/// The targets are starting points measured on a projected, two-dimensional body. A camera
/// cannot see depth, so a pose is checked from whichever side actually shows its shape, and
/// the numbers are deliberately forgiving. Use Pose Lab to see what your own body reads
/// before tightening anything.
enum AsanaLibrary {
    static let all: [Asana] = standing + balance + strength + backbends + hips + restore

    static func asana(id: String) -> Asana? {
        all.first { $0.id == id }
    }

    static func asanas(ids: [String]) -> [Asana] {
        ids.compactMap { asana(id: $0) }
    }

    static func inCategory(_ category: AsanaCategory) -> [Asana] {
        all.filter { $0.category == category }
    }

    // MARK: - Standing & Legs

    static let standing: [Asana] = [
        Asana(
            id: "mountain", name: "Mountain", sanskrit: "Tadasana", category: .standing,
            symbol: "figure.stand",
            summary: "Standing still, evenly, with everything stacked.",
            benefits: "Teaches the posture every other standing pose is built on.",
            steps: [
                "Stand with your feet under your hips, weight even on both.",
                "Lift the top of your head, let your shoulders drop back.",
                "Arms by your sides, palms forward, and breathe.",
            ],
            facing: .front,
            requirements: [
                .atMost(.metric(.spineTilt), 8, "Stand tall, stack your shoulders over your hips"),
                .atMost(.metric(.shoulderTilt), 7, "Level your shoulders"),
                .atMost(.metric(.hipTilt), 7, "Level your hips"),
                .atLeast(.pair(.leftKnee), 165, "Straighten your legs without locking your knees"),
                .atMost(.metric(.stanceWidth), 0.6, "Bring your feet under your hips"),
            ],
            figure: FigurePose(),
            holdBreaths: 5, twoSided: false, level: .beginner
        ),
        Asana(
            id: "chair", name: "Chair", sanskrit: "Utkatasana", category: .standing,
            symbol: "figure.strengthtraining.functional",
            summary: "Sitting back into an invisible chair with your arms overhead.",
            benefits: "Builds thighs, glutes and stamina, and opens the shoulders.",
            steps: [
                "Feet together, then bend your knees and sit your hips back.",
                "Keep your weight in your heels so you could see your toes.",
                "Sweep your arms up alongside your ears and lift your chest.",
            ],
            facing: .side,
            requirements: [
                .atMost(.pair(.leftKnee), 130, "Sit lower, bend your knees more"),
                .atLeast(.pair(.leftKnee), 80, "Come up a little, keep your knees above your ankles"),
                .atLeast(.metric(.handHeight), 1.3, "Reach your arms up alongside your ears"),
                .near(.metric(.spineTilt), 30, 16, "Lift your chest instead of folding forward"),
                .atLeast(.pair(.leftElbow), 150, "Straighten your arms"),
            ],
            figure: FigurePose(spine: 30, head: 25,
                               leftUpperArm: 18, leftForearm: 14, rightUpperArm: 14, rightForearm: 10,
                               leftThigh: 142, leftShin: 200, rightThigh: 138, rightShin: 198),
            holdBreaths: 5, twoSided: false, level: .intermediate
        ),
        Asana(
            id: "warrior-one", name: "Warrior I", sanskrit: "Virabhadrasana I", category: .standing,
            symbol: "figure.martial.arts",
            summary: "A deep lunge with a straight back leg and both arms overhead.",
            benefits: "Strengthens the legs, opens the hip flexors and the chest.",
            steps: [
                "Step your left foot forward into a long lunge.",
                "Bend your front knee toward a right angle, over the ankle.",
                "Press your back heel down and reach both arms up.",
            ],
            facing: .side,
            requirements: [
                .near(.angle(.leftKnee), 97, 20, "Bend your front knee toward a right angle"),
                .atLeast(.angle(.rightKnee), 150, "Straighten your back leg"),
                .atMost(.metric(.spineTilt), 20, "Lift your chest and stand your torso up"),
                .atLeast(.metric(.handHeight), 1.3, "Reach both arms overhead"),
                .atMost(.metric(.hipHeight), 0.98, "Sink lower into the lunge"),
            ],
            figure: FigurePose(spine: 6, head: 4,
                               leftUpperArm: 4, leftForearm: 2, rightUpperArm: -4, rightForearm: -2,
                               leftThigh: 100, leftShin: 183, rightThigh: 215, rightShin: 200),
            holdBreaths: 5, twoSided: true, level: .intermediate
        ),
        Asana(
            id: "warrior-two", name: "Warrior II", sanskrit: "Virabhadrasana II", category: .standing,
            symbol: "figure.martial.arts",
            summary: "A wide stance, a bent front knee and arms reaching out level.",
            benefits: "Opens the hips and the chest while the legs work hard.",
            steps: [
                "Step wide, turn your left foot out and your back foot in slightly.",
                "Bend your front knee so it tracks over your ankle.",
                "Reach your arms out level with the floor and look past your front hand.",
            ],
            facing: .front,
            requirements: [
                .atMost(.angle(.leftKnee), 132, "Bend your front knee deeper"),
                .atLeast(.angle(.leftKnee), 80, "Ease up, keep your knee above your ankle"),
                .atLeast(.angle(.rightKnee), 150, "Straighten your back leg"),
                .atMost(.metric(.spineTilt), 14, "Stack your shoulders over your hips, don't lean"),
                .atMost(.metric(.leftArmTilt), 14, "Reach both arms level with the floor"),
                .atMost(.metric(.rightArmTilt), 14, "Reach both arms level with the floor"),
                .atLeast(.metric(.stanceWidth), 1.25, "Step your feet wider apart"),
            ],
            figure: FigurePose(spine: 0, head: 0,
                               leftUpperArm: 270, leftForearm: 270, rightUpperArm: 90, rightForearm: 90,
                               leftThigh: 245, leftShin: 180, rightThigh: 150, rightShin: 155),
            holdBreaths: 5, twoSided: true, level: .beginner
        ),
        Asana(
            id: "triangle", name: "Triangle", sanskrit: "Trikonasana", category: .standing,
            symbol: "triangle",
            summary: "Straight legs, a long side body, and arms in one line.",
            benefits: "Stretches the hamstrings and side body, and opens the chest.",
            steps: [
                "From a wide stance, turn your left foot out and keep both legs straight.",
                "Reach over your front leg, then let your bottom hand rest on your shin.",
                "Stack your top shoulder and reach that arm straight up.",
            ],
            facing: .front,
            requirements: [
                .atLeast(.pair(.leftKnee), 158, "Keep both legs straight"),
                .near(.metric(.spineTilt), 50, 22, "Tip your torso sideways over your front leg"),
                .atLeast(.metric(.armSpread), 1.8, "Open your arms into one long line"),
                .atLeast(.metric(.stanceWidth), 1.35, "Step your feet wider apart"),
                .atLeast(.pair(.leftElbow), 150, "Keep both arms straight"),
            ],
            figure: FigurePose(spine: 305, head: 300,
                               leftUpperArm: 215, leftForearm: 215, rightUpperArm: 35, rightForearm: 35,
                               leftThigh: 215, leftShin: 205, rightThigh: 145, rightShin: 155),
            holdBreaths: 5, twoSided: true, level: .intermediate
        ),
        Asana(
            id: "goddess", name: "Goddess", sanskrit: "Utkata Konasana", category: .standing,
            symbol: "figure.stand",
            summary: "A wide squat with the knees open and the arms in a cactus.",
            benefits: "Strong work for the inner thighs and glutes, and opens the hips.",
            steps: [
                "Step wide and turn your toes out to about forty-five degrees.",
                "Bend both knees and sink your hips toward knee height.",
                "Bring your arms up with your elbows at right angles, palms forward.",
            ],
            facing: .front,
            requirements: [
                .atMost(.pair(.leftKnee), 132, "Sink your hips lower, knees tracking over your toes"),
                .atLeast(.pair(.leftKnee), 80, "Come up a little"),
                .atLeast(.metric(.stanceWidth), 1.4, "Step your feet wider apart"),
                .atMost(.metric(.spineTilt), 14, "Keep your spine tall and your chest open"),
                .near(.pair(.leftElbow), 105, 30, "Bend your elbows to right angles, palms forward"),
            ],
            figure: FigurePose(spine: 0, head: 0,
                               leftUpperArm: 290, leftForearm: 0, rightUpperArm: 70, rightForearm: 0,
                               leftThigh: 235, leftShin: 175, rightThigh: 125, rightShin: 185),
            holdBreaths: 5, twoSided: false, level: .intermediate
        ),
    ]

    // MARK: - Balance

    static let balance: [Asana] = [
        Asana(
            id: "tree", name: "Tree", sanskrit: "Vrksasana", category: .balance,
            symbol: "tree",
            summary: "Standing on one leg with the other foot pressed into your inner leg.",
            benefits: "Builds balance, ankle strength and focus.",
            steps: [
                "Stand tall, then shift your weight onto your right foot.",
                "Place your left foot on your calf or inner thigh, never on the knee.",
                "Press foot and leg together, then reach your arms overhead.",
            ],
            facing: .front,
            requirements: [
                .atLeast(.angle(.rightKnee), 162, "Stand tall on your standing leg"),
                .atMost(.angle(.leftKnee), 80, "Draw your lifted foot higher up your leg"),
                .atLeast(.metric(.ankleLift), 0.4, "Lift your foot off the floor"),
                .atMost(.metric(.spineTilt), 11, "Stand tall, don't lean out to the side"),
                .atLeast(.metric(.handHeight), 1.2, "Reach your arms overhead"),
            ],
            figure: FigurePose(spine: 0, head: 0,
                               leftUpperArm: 4, leftForearm: 2, rightUpperArm: -4, rightForearm: -2,
                               leftThigh: 250, leftShin: 30, rightThigh: 178, rightShin: 179),
            holdBreaths: 5, twoSided: true, level: .beginner
        ),
        Asana(
            id: "warrior-three", name: "Warrior III", sanskrit: "Virabhadrasana III", category: .balance,
            symbol: "figure.flexibility",
            summary: "Balanced on one leg with your body and lifted leg level like a letter T.",
            benefits: "Demanding work for balance, hamstrings, glutes and the whole back.",
            steps: [
                "From standing, shift onto your right foot and hinge forward at the hip.",
                "Reach your left leg straight back until it is level with your hips.",
                "Reach your arms forward and make one long line from hands to heel.",
            ],
            facing: .side,
            requirements: [
                .near(.metric(.spineTilt), 85, 24, "Bring your torso parallel to the floor"),
                .atLeast(.angle(.leftHip), 145, "Reach your lifted leg back in line with your body"),
                .atLeast(.angle(.rightKnee), 155, "Straighten your standing leg"),
                .atLeast(.angle(.leftKnee), 150, "Straighten your lifted leg"),
                .atLeast(.metric(.ankleLift), 0.65, "Lift your back foot to hip height"),
            ],
            figure: FigurePose(spine: 95, head: 80,
                               leftUpperArm: 85, leftForearm: 85, rightUpperArm: 88, rightForearm: 88,
                               leftThigh: 272, leftShin: 268, rightThigh: 182, rightShin: 180),
            holdBreaths: 4, twoSided: true, level: .advanced,
            caution: "Come down the moment your standing knee starts to wobble."
        ),
        Asana(
            id: "half-moon", name: "Half Moon", sanskrit: "Ardha Chandrasana", category: .balance,
            symbol: "moonphase.first.quarter",
            summary: "Balanced on one hand and one foot with the top leg and arm open.",
            benefits: "Balance, hip opening and a strong side body.",
            steps: [
                "From a lunge, reach your bottom hand to the floor ahead of your front foot.",
                "Straighten your standing leg and float your left leg up to hip height.",
                "Open your chest and stack your top arm straight up.",
            ],
            facing: .side,
            requirements: [
                .near(.metric(.spineTilt), 80, 26, "Open your chest, torso level with the floor"),
                .atLeast(.angle(.rightKnee), 155, "Straighten your standing leg"),
                .atLeast(.metric(.ankleLift), 0.65, "Lift your top leg to hip height"),
                .atLeast(.metric(.armSpread), 1.7, "Stack your top arm over the bottom one"),
                .atLeast(.angle(.leftKnee), 150, "Straighten your lifted leg"),
            ],
            figure: FigurePose(spine: 95, head: 85,
                               leftUpperArm: 2, leftForearm: 2, rightUpperArm: 178, rightForearm: 178,
                               leftThigh: 275, leftShin: 272, rightThigh: 180, rightShin: 180),
            holdBreaths: 4, twoSided: true, level: .advanced,
            caution: "Practise near a wall first, and use a block under the bottom hand."
        ),
        Asana(
            id: "dancer", name: "Dancer", sanskrit: "Natarajasana", category: .balance,
            symbol: "figure.dance",
            summary: "Standing on one leg, holding the other foot behind you as the chest tips forward.",
            benefits: "Opens the chest, shoulders and hip flexors while testing your balance.",
            steps: [
                "Stand on your right foot and bend your left knee behind you.",
                "Catch the inside of your left foot with your left hand.",
                "Press the foot back into the hand and reach your other arm forward.",
            ],
            facing: .side,
            requirements: [
                .atLeast(.angle(.rightKnee), 155, "Straighten your standing leg"),
                .atMost(.angle(.leftKnee), 115, "Bend your lifted knee and press the foot into your hand"),
                .atLeast(.metric(.ankleLift), 0.75, "Lift your back foot higher"),
                .near(.metric(.spineTilt), 35, 22, "Tip your chest forward as the leg lifts back"),
            ],
            figure: FigurePose(spine: 35, head: 20,
                               leftUpperArm: 320, leftForearm: 340, rightUpperArm: 60, rightForearm: 55,
                               leftThigh: 300, leftShin: 30, rightThigh: 178, rightShin: 180),
            holdBreaths: 4, twoSided: true, level: .advanced,
            caution: "Keep the lifting gentle. Never force the knee."
        ),
    ]

    // MARK: - Core & Strength

    static let strength: [Asana] = [
        Asana(
            id: "plank", name: "Plank", sanskrit: "Phalakasana", category: .strength,
            symbol: "figure.core.training",
            summary: "One straight line from the crown of your head to your heels.",
            benefits: "The core, shoulder and wrist strength every arm balance is built on.",
            steps: [
                "Come to your hands and knees, then step both feet back.",
                "Stack your shoulders over your wrists and press the floor away.",
                "Draw your belly in so your hips neither sag nor pike up.",
            ],
            facing: .side,
            requirements: [
                .atLeast(.pair(.leftHip), 158, "Bring your hips into one straight line"),
                .atLeast(.pair(.leftElbow), 158, "Straighten your arms, shoulders over wrists"),
                .atLeast(.pair(.leftKnee), 158, "Straighten your legs and press your heels back"),
                .near(.metric(.spineTilt), 90, 24, "Hold your body level with the floor"),
            ],
            figure: FigurePose(spine: 100, head: 90,
                               leftUpperArm: 178, leftForearm: 178, rightUpperArm: 182, rightForearm: 182,
                               leftThigh: 278, leftShin: 278, rightThigh: 276, rightShin: 276),
            holdBreaths: 5, twoSided: false, level: .intermediate
        ),
        Asana(
            id: "side-plank", name: "Side Plank", sanskrit: "Vasisthasana", category: .strength,
            symbol: "figure.core.training",
            summary: "Balanced on one hand and the edge of one foot, body on a long diagonal.",
            benefits: "Strong obliques, shoulders and wrists.",
            steps: [
                "From plank, roll onto the outside edge of your left foot.",
                "Stack your shoulders and lift your hips until your body is one line.",
                "Reach your top arm straight up and look wherever your neck is happy.",
            ],
            facing: .front,
            requirements: [
                .atLeast(.pair(.leftHip), 152, "Lift your hips into one straight line"),
                .atLeast(.angle(.leftElbow), 152, "Straighten your supporting arm"),
                .near(.metric(.spineTilt), 25, 22, "Hold your body on a long diagonal"),
                .atLeast(.metric(.armSpread), 1.7, "Reach your top arm straight up"),
            ],
            figure: FigurePose(spine: 340, head: 335,
                               leftUpperArm: 215, leftForearm: 215, rightUpperArm: 35, rightForearm: 35,
                               leftThigh: 150, leftShin: 150, rightThigh: 152, rightShin: 152),
            holdBreaths: 4, twoSided: true, level: .advanced,
            caution: "Drop the bottom knee to the floor if the wrist complains."
        ),
        Asana(
            id: "boat", name: "Boat", sanskrit: "Navasana", category: .strength,
            symbol: "sailboat",
            summary: "Balanced on your sitting bones in a V, legs lifted and arms forward.",
            benefits: "Deep abdominal and hip flexor strength.",
            steps: [
                "Sit down, lean back and lift your feet off the floor.",
                "Straighten your legs if you can, or keep the shins level to start.",
                "Reach your arms forward beside your knees and lift your chest.",
            ],
            facing: .side,
            requirements: [
                .near(.pair(.leftHip), 85, 24, "Make a V: lift your chest and your legs together"),
                .atLeast(.pair(.leftKnee), 145, "Straighten your legs if your back allows"),
                .atMost(.metric(.hipHeight), -0.15, "Lift your feet above hip height"),
                .atMost(.metric(.leftArmTilt), 22, "Reach your arms forward, level with the floor"),
                .atMost(.metric(.rightArmTilt), 22, "Reach your arms forward, level with the floor"),
            ],
            figure: FigurePose(spine: 330, head: 335,
                               leftUpperArm: 95, leftForearm: 95, rightUpperArm: 93, rightForearm: 93,
                               leftThigh: 55, leftShin: 45, rightThigh: 57, rightShin: 47),
            holdBreaths: 4, twoSided: false, level: .intermediate
        ),
        Asana(
            id: "down-dog", name: "Downward Dog", sanskrit: "Adho Mukha Svanasana", category: .strength,
            symbol: "triangle",
            summary: "An upside-down V: hips high, arms and legs long.",
            benefits: "Lengthens hamstrings and calves, strengthens shoulders, resets everything.",
            steps: [
                "From hands and knees, tuck your toes and lift your hips up and back.",
                "Press the floor away and make your spine long.",
                "Let your heels move toward the floor. They do not have to arrive.",
            ],
            facing: .side,
            requirements: [
                .near(.pair(.leftHip), 85, 24, "Lift your hips up and back into a long V"),
                .atLeast(.pair(.leftKnee), 145, "Reach your heels down and straighten your legs"),
                .atLeast(.pair(.leftElbow), 152, "Straighten your arms and press the floor away"),
                .atLeast(.metric(.reach), 1.5, "Walk your hands and feet further apart"),
                .atLeast(.metric(.hipHeight), 0.5, "Lift your hips higher"),
            ],
            figure: FigurePose(spine: 125, head: 130,
                               leftUpperArm: 145, leftForearm: 145, rightUpperArm: 143, rightForearm: 143,
                               leftThigh: 205, leftShin: 195, rightThigh: 207, rightShin: 197),
            holdBreaths: 6, twoSided: false, level: .beginner
        ),
    ]

    // MARK: - Backbends

    static let backbends: [Asana] = [
        Asana(
            id: "cobra", name: "Cobra", sanskrit: "Bhujangasana", category: .backbend,
            symbol: "figure.flexibility",
            summary: "Lying face down with the chest lifted and the hips heavy.",
            benefits: "Opens the chest, strengthens the back of the body, undoes desk posture.",
            steps: [
                "Lie on your front with your hands under your shoulders.",
                "Press the tops of your feet down and lift your chest.",
                "Draw your shoulders back and keep your elbows close to your ribs.",
            ],
            facing: .side,
            requirements: [
                .near(.metric(.spineTilt), 55, 26, "Lift your chest and roll your shoulders back"),
                .atMost(.metric(.hipHeight), 0.35, "Keep your hips and legs down on the floor"),
                .atLeast(.pair(.leftKnee), 150, "Keep your legs long and straight behind you"),
                .atLeast(.pair(.leftHip), 130, "Lengthen through your hips, don't crunch your low back"),
            ],
            figure: FigurePose(spine: 60, head: 45,
                               leftUpperArm: 175, leftForearm: 178, rightUpperArm: 177, rightForearm: 179,
                               leftThigh: 268, leftShin: 268, rightThigh: 266, rightShin: 266),
            holdBreaths: 5, twoSided: false, level: .beginner,
            caution: "Come only as high as your low back stays comfortable."
        ),
        Asana(
            id: "bridge", name: "Bridge", sanskrit: "Setu Bandha Sarvangasana", category: .backbend,
            symbol: "figure.flexibility",
            summary: "On your back with your feet planted and your hips lifted.",
            benefits: "Opens the front of the hips and chest, strengthens glutes and hamstrings.",
            steps: [
                "Lie on your back and walk your heels close to your hips.",
                "Press down through your feet and lift your hips.",
                "Roll your shoulders under and let your chest move toward your chin.",
            ],
            facing: .side,
            requirements: [
                .atLeast(.pair(.leftHip), 125, "Lift your hips higher"),
                .near(.pair(.leftKnee), 85, 28, "Walk your feet closer so your shins stand upright"),
                .atLeast(.metric(.hipHeight), 0.2, "Press your feet down and lift"),
                .atMost(.pair(.leftShinTilt), 38, "Stack your knees over your ankles"),
            ],
            figure: FigurePose(spine: 115, head: 105,
                               leftUpperArm: 250, leftForearm: 252, rightUpperArm: 248, rightForearm: 250,
                               leftThigh: 250, leftShin: 160, rightThigh: 252, rightShin: 162),
            holdBreaths: 5, twoSided: false, level: .beginner
        ),
        Asana(
            id: "locust", name: "Locust", sanskrit: "Salabhasana", category: .backbend,
            symbol: "figure.flexibility",
            summary: "Face down, lifting chest, arms and legs off the floor together.",
            benefits: "Wakes up the whole back of the body. The antidote to sitting.",
            steps: [
                "Lie on your front with your arms alongside your body.",
                "Lift your chest, arms and both legs at the same time.",
                "Reach back through your fingers and long through your toes.",
            ],
            facing: .side,
            requirements: [
                .near(.metric(.spineTilt), 48, 26, "Lift your chest off the floor"),
                .atMost(.metric(.hipHeight), -0.05, "Lift both legs off the floor"),
                .atLeast(.pair(.leftKnee), 150, "Keep your legs straight as they lift"),
                .atLeast(.pair(.leftElbow), 145, "Reach your arms straight back"),
            ],
            figure: FigurePose(spine: 62, head: 50,
                               leftUpperArm: 250, leftForearm: 250, rightUpperArm: 248, rightForearm: 248,
                               leftThigh: 285, leftShin: 283, rightThigh: 283, rightShin: 281),
            holdBreaths: 4, twoSided: false, level: .intermediate
        ),
        Asana(
            id: "camel", name: "Camel", sanskrit: "Ustrasana", category: .backbend,
            symbol: "figure.flexibility",
            summary: "Kneeling and arching back with your hands reaching for your heels.",
            benefits: "A deep opening for the chest, shoulders and hip flexors.",
            steps: [
                "Kneel with your hips stacked over your knees, hips width apart.",
                "Press your hips forward and lift your chest up and back.",
                "Reach your hands to your heels only if your chest stays lifted.",
            ],
            facing: .side,
            requirements: [
                .near(.pair(.leftKnee), 92, 24, "Kneel with your hips over your knees"),
                .atLeast(.pair(.leftHip), 145, "Press your hips forward as you arch back"),
                .atLeast(.metric(.spineTilt), 14, "Lift your chest and arch back gently"),
                .atMost(.metric(.handHeight), 0.25, "Reach your hands back toward your heels"),
            ],
            figure: FigurePose(spine: 340, head: 315,
                               leftUpperArm: 215, leftForearm: 210, rightUpperArm: 213, rightForearm: 208,
                               leftThigh: 180, leftShin: 265, rightThigh: 178, rightShin: 263),
            holdBreaths: 4, twoSided: false, level: .advanced,
            caution: "Skip this one if you have neck or low back pain. Keep the head neutral."
        ),
    ]

    // MARK: - Hips & Forward Folds

    static let hips: [Asana] = [
        Asana(
            id: "forward-fold", name: "Forward Fold", sanskrit: "Uttanasana", category: .hips,
            symbol: "figure.cooldown",
            summary: "Standing and folding all the way forward from the hips.",
            benefits: "Lengthens hamstrings and the whole back, and quietens the mind.",
            steps: [
                "Stand with your feet hip width apart, hands on your hips.",
                "Hinge from the hips and fold, letting your head hang heavy.",
                "Keep a soft bend in the knees if your hamstrings are tight.",
            ],
            facing: .side,
            requirements: [
                .atMost(.pair(.leftHip), 78, "Fold deeper from your hips, not your waist"),
                .atLeast(.pair(.leftKnee), 150, "Straighten your legs as much as feels kind"),
                .atLeast(.metric(.spineTilt), 62, "Let your torso hang down toward the floor"),
                .atMost(.metric(.handHeight), -0.4, "Let your hands drop toward the floor"),
            ],
            figure: FigurePose(spine: 118, head: 150,
                               leftUpperArm: 182, leftForearm: 182, rightUpperArm: 180, rightForearm: 180,
                               leftThigh: 181, leftShin: 180, rightThigh: 179, rightShin: 178),
            holdBreaths: 6, twoSided: false, level: .beginner
        ),
        Asana(
            id: "half-fold", name: "Half Forward Fold", sanskrit: "Ardha Uttanasana", category: .hips,
            symbol: "figure.cooldown",
            summary: "A flat back at hip height, hands on the shins.",
            benefits: "Teaches a long spine, which is what makes every fold safe.",
            steps: [
                "From a forward fold, slide your hands to your shins.",
                "Lift your chest until your back is flat as a table.",
                "Draw your shoulders away from your ears and look down.",
            ],
            facing: .side,
            requirements: [
                .near(.pair(.leftHip), 90, 22, "Hips back, chest forward, back flat as a table"),
                .atLeast(.pair(.leftKnee), 150, "Straighten your legs"),
                .near(.metric(.spineTilt), 85, 22, "Lengthen your spine parallel to the floor"),
                .atMost(.metric(.handHeight), -0.45, "Rest your hands on your shins"),
            ],
            figure: FigurePose(spine: 95, head: 80,
                               leftUpperArm: 182, leftForearm: 182, rightUpperArm: 180, rightForearm: 180,
                               leftThigh: 181, leftShin: 180, rightThigh: 179, rightShin: 178),
            holdBreaths: 4, twoSided: false, level: .beginner
        ),
        Asana(
            id: "low-lunge", name: "Low Lunge", sanskrit: "Anjaneyasana", category: .hips,
            symbol: "figure.flexibility",
            summary: "A lunge with the back knee resting down and the arms reaching up.",
            benefits: "The best everyday opener for tight hip flexors.",
            steps: [
                "Step your left foot forward and lower your back knee to the floor.",
                "Slide the back knee until you feel the front of that hip open.",
                "Sweep your arms overhead and lift your chest.",
            ],
            facing: .side,
            requirements: [
                .near(.angle(.leftKnee), 95, 22, "Stack your front knee over your ankle"),
                .near(.angle(.rightKnee), 95, 28, "Let your back knee rest under your hip"),
                .atLeast(.metric(.handHeight), 1.2, "Sweep your arms overhead"),
                .atMost(.metric(.spineTilt), 22, "Lift your chest tall, don't dump into your low back"),
            ],
            figure: FigurePose(spine: 6, head: 4,
                               leftUpperArm: 6, leftForearm: 3, rightUpperArm: -6, rightForearm: -3,
                               leftThigh: 105, leftShin: 182, rightThigh: 190, rightShin: 272),
            holdBreaths: 5, twoSided: true, level: .beginner,
            caution: "Put a folded blanket under the back knee if the floor is hard."
        ),
        Asana(
            id: "seated-fold", name: "Seated Forward Fold", sanskrit: "Paschimottanasana", category: .hips,
            symbol: "figure.cooldown",
            summary: "Sitting with your legs long and folding over them.",
            benefits: "A quiet, deep stretch for the hamstrings and the whole back line.",
            steps: [
                "Sit with your legs straight out and your feet flexed.",
                "Lengthen your spine first, then hinge forward from the hips.",
                "Reach for your shins, ankles or feet, wherever you land.",
            ],
            facing: .side,
            requirements: [
                .atMost(.pair(.leftHip), 68, "Fold forward from the hips, over your legs"),
                .atLeast(.pair(.leftKnee), 150, "Keep your legs straight and your feet flexed"),
                .atMost(.metric(.hipHeight), 0.4, "Sit down on the floor with your legs long"),
                .atMost(.metric(.reach), 0.75, "Reach your hands toward your feet"),
            ],
            figure: FigurePose(spine: 60, head: 80,
                               leftUpperArm: 105, leftForearm: 100, rightUpperArm: 103, rightForearm: 98,
                               leftThigh: 95, leftShin: 93, rightThigh: 93, rightShin: 91),
            holdBreaths: 6, twoSided: false, level: .beginner
        ),
    ]

    // MARK: - Rest & Breath

    static let restore: [Asana] = [
        Asana(
            id: "child", name: "Child's Pose", sanskrit: "Balasana", category: .restore,
            symbol: "leaf",
            summary: "Kneeling with your hips back to your heels and your forehead down.",
            benefits: "The rest position of yoga. Come here any time, in any practice.",
            steps: [
                "Kneel and bring your big toes together, knees as wide as feels good.",
                "Sit your hips back toward your heels.",
                "Walk your hands forward and let your forehead rest down.",
            ],
            facing: .side,
            requirements: [
                .atMost(.pair(.leftHip), 65, "Fold your chest down toward your thighs"),
                .atMost(.pair(.leftKnee), 75, "Sit your hips back toward your heels"),
                .atMost(.metric(.hipHeight), 0.55, "Let your hips settle down"),
                .atMost(.metric(.handHeight), 0.15, "Walk your hands forward and rest"),
            ],
            figure: FigurePose(spine: 110, head: 130,
                               leftUpperArm: 115, leftForearm: 110, rightUpperArm: 113, rightForearm: 108,
                               leftThigh: 140, leftShin: 280, rightThigh: 138, rightShin: 278),
            holdBreaths: 8, twoSided: false, level: .beginner
        ),
        Asana(
            id: "corpse", name: "Corpse Pose", sanskrit: "Savasana", category: .restore,
            symbol: "moon.zzz",
            summary: "Lying flat and completely still, which is harder than it sounds.",
            benefits: "Lets everything you just practised settle. Never skip it.",
            steps: [
                "Lie on your back with your legs long and slightly apart.",
                "Let your arms rest away from your body, palms up.",
                "Close your eyes and let the breath do whatever it wants.",
            ],
            facing: .side,
            requirements: [
                .atLeast(.pair(.leftHip), 160, "Let your whole body rest long on the floor"),
                .atLeast(.pair(.leftKnee), 155, "Let your legs relax out straight"),
                .near(.metric(.spineTilt), 90, 22, "Lie flat on your back"),
            ],
            figure: FigurePose(spine: 90, head: 85,
                               leftUpperArm: 250, leftForearm: 250, rightUpperArm: 252, rightForearm: 252,
                               leftThigh: 272, leftShin: 272, rightThigh: 270, rightShin: 270),
            holdBreaths: 10, twoSided: false, level: .beginner
        ),
    ]
}
