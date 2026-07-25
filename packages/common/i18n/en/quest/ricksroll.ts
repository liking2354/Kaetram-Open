export default {
    name: 'Rick\'s Roll',
    description: 'Rick needs help to make his famous roll to be together forever with his girlfriend.|Rick finds himself in need of assistance to create his famous roll. Go talk to him and see what he needs! ',
    rewards: ["1987 Cooking experience"],
    stages: {
        0: {
            text: [
                'Hello adventurer please help me.',
                'Me and my girlfriend are no strangers to love',
                'She knows the rules and so do I',
                'A full commitment’s what I’m thinking of',
                'She wouldn’t get this from any other guy',
                'I just wanna tell her how I’m feeling',
                'Gotta make her understand',
                'That\'s why I need your help',
                'Please bring me 5 cooked shrimps',
                'They are the key ingredients of my perfect rolls',
                'I need to make it so we could be together forever',
            ],
            completedText: [
                'Don\'t give up on me',
                'Don\'t let me down',
                'Don\'t let me say goodbye',
                'Please bring me 5 cooked shrimps',
            ],
        },
        1: {
            completedText: [
                'Don\'t give up on me',
                'Don\'t let me down',
                'Don\'t let me say goodbye',
                'Please deliver my rolls to my girlfriend, Lena!',
            ],
            hasItemText: [
                'Thank you. I\'m so touched',
                'I\'ll never gonna go around and desert you',
                'Give me a second',
                '....',
                '....',
                'Perfect!',
                'Could you do me a favour and give my rolls to my girlfriend?',
            ],
        },
        3: {
            hasItemText: [
                'Oh!',
                'Is this from Rick?',
                'Thank you so much adventurer!',
                'Please take this as a token of my appreciation',
            ],
        },
    }
} as const;