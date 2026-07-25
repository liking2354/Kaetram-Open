export default {
    name: 'Herbalist\'s Desperation',
    description: 'A local herbalist is in dire need of rare herbs.|The small village of Lakesworld relies on the potions of a local herbalist for their daily needs. However, the herbalist has run out of their most important ingredients and seeks the aid of a brave adventurer. Travel to the Misty Marshlands and obtain these elusive herbs for them.',
    rewards: ["Mystical Potion", "1500 Foraging experience"],
    stages: {
        0: {
            text: [
                'Ah, adventurer! Just the person I was hoping to see.',
                'You see, I have a bit of a predicament.',
                'The herbs I need for my potions are all gone!',
                'Could you fetch me 3 Blue Lilies?',
                'I would go myself, but the marshes are treacherous and I am no fighter.',
            ],
            completedText: [
                'The villagers are crossing their fingers, toes, and spaghetti noodles in anticipation.',
                'Please bring back 3 Blue Lilies.',
            ],
        },
        1: {
            completedText: [
                'The villagers are getting restless.',
                'Please bring back 2 paprikas and 2 tomatoes.',
            ],
            hasItemText: [
                'Ah! These are perfect! However...',
                'It seems I\'ve omitted to mention a few more ingredients.',
                'My bad, it\'s been a wacky day.',
                'Could you kindly round up 2 paprikas and 2 tomatoes for me?',
                'I have a hunch they\'re lurking nearby',
                'I promise, this will be the last request.',
            ],
        },
        2: {
            hasItemText: [
                'You\'ve done it! The potions can now be made.',
                'Thank you, brave adventurer. Take this potion as a token of my never-ending gratitude.',
                'See you around!',
            ],
        },
    }
} as const;