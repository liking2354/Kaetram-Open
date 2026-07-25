export default {
    name: 'Arts and Crafts',
    description: 'Help the old lady on the great mountai with her crafts.|The old lady on the great mountain is very cold and needs a brave adventurer to run errands for her. In exchange you will be taught how to start crafting items.',
    rewards: ["Access to crafting benches"],
    stages: {
        0: {
            text: [
                'Hello there young one...',
                'Would you be interested in learning how to craft things?',
                'I can teach you, but you\'ll need to bring me some materials first.',
                'I\'m gonna teach you how to make pendants.',
                'First bring me some string, you can craft it by finding blue lilies.',
                'Secondly I will need some beryl, you can find it in various caves.',
                'You can use the crafting table to make a Beryl Pendant.',
            ],
            completedText: [
                'Bring me some string and some beryl gemstone and use it to make a pendant.',
            ],
        },
        1: {
            completedText: [
                'Fletch me a small bowl and bring it to me.',
            ],
            hasItemText: [
                'Wonderful, now you can use crafting in combination with other skills',
                'to create more complex items. Fletch a small bowl and bring it to me.',
            ],
        },
        2: {
            completedText: [
                'Try making a stew using a bowl, a tomato, and the cauldron.',
            ],
            hasItemText: [
                'Perfect, I\'m gonna take that bowl just to annoy you. Go make another',
                'one and use this tomato to make a stew using the cauldron.',
                'You may need to go find the rest of the ingredients, I\'m getting old.',
            ],
        },
        3: {
            hasItemText: [
                'Wonderful, see, you\'re getting the hang of it.',
            ],
        },
    }
} as const;