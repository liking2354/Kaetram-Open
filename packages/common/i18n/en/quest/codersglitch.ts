export default {
    name: 'The Coder\'s Glitch',
    description: 'The coder requires your help sorting out his bugs.|The coder (as you were probably told about in the tutorial if you didn\'t skip it), requires your help with defeating the bugs he has created. He seeks the trophy of the first three bosses.',
    rewards: ["5000 strength experience", "A surprise weapon"],
    stages: {
        0: {
            text: [
                'Alright perfect, seems you have gotten the gist of how this world works.',
                'One of my first glitches is the Skeleton King.',
                'I created this entity due to needing a boss in this ga- I mean, world.',
                'Turns out he\'s rather unstable and tends to attack random people in his',
                'suspiciously boss-like-shaped room. I need you to defeat him and bring me',
                'his head as a trophy.',
                'The skeleton king resides east of the desert within',
                'the volcano land known as Patsow.',
            ],
            completedText: [
                'Find and defeat the Skeleton King. He\'s located east of the desert.',
                'Within the lavalands known as Patsow. Bring me his talisman.',
            ],
        },
        2: {
            hasItemText: [
                'Wow I really didn\'t think I\'d see you aga-',
                'Sorry, congratulations hero! Thank you for doing this task for me.',
                'It is super important that you do this for me, as I need to test',
                'the limits of the real cod- I mean, the limits of this world.',
                'Well, regardless. I may have another task for you in the nearby future.',
                'Why don\'t you go and explore the world a bit more? I\'m sure you\'ll',
                'find something or someone interesting...',
            ],
        },
    }
} as const;