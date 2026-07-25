export default {
    name: 'Ancient Lands',
    description:
        "Discover the lands that lie beyond the great mountains.|A very spooky monument lies hidden in a peculiar icy place. You can find it by exploring the caves in the swamp lands. They may or may not be guarded by some ice golems or something, but you didn't hear that from me, I wouldn't possibly want to spoil anything for you.",
    rewards: ['Snow potion', 'Access to the mountains beyond'],
    stages: {
        0: {
            text: [
                'You seek to venture further east to the great beyond?',
                'Adventurer, I recognize your past experience',
                'I was there when you first arrived in this land.',
                'Should you know of the perils, I may not hold you back.',
                'But you must first complete a task to unlock the path.',
                'South of here lies a great maze, dark, cold, and full of perils.',
                'You must bring back the ancient ice sword lost within.',
                'In exchange, I will grant you access to the ancient lands.',
                'As well as knowledge of the snow potions, necessary for your survival beyond.'
            ],
            completedText: ['Find the ancient ice sword!']
        },
        1: {
            hasItemText: [
                'You have returned with the ancient ice sword?',
                'I see, you have proven yourself worthy.',
                'Take this knowledge of the snow potions, and the path shall be yours.'
            ]
        }
    }
} as const;
