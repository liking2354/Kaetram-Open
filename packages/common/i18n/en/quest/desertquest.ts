export default {
    name: 'Desert Quest',
    description: 'Help the dying adventurer send a letter to his wife.|The adventurer is dying and is in dire need of your help with super important matters prior to his death. You can find him in the desert.',
    rewards: ["Secret Reward"],
    stages: {
        0: {
            text: [
                'Please dear adventurer, beware of what lies ahead.',
                'I am no longer able to carry on forth.',
                'Would you please be so kind as to aid me?',
                'I must tell my wife I will no longer be coming home.',
                'Could you deliver this CD for me?',
                'She lives south of the desert.',
            ],
            completedText: [
                'Please adventurer, deliver the CD.',
                'It\'s my new Demo Tape, I must ensure she hears it.',
            ],
        },
        1: {
            text: [
                'Hello? Why are you in my house..?',
            ],
            completedText: [
                'Go on now, tell him.',
            ],
            hasItemText: [
                'Who are you and why are you in my house?',
                'Is it about my husband?',
                'Oh my god I knew it, that bastard is cheating on me!',
                'Wait, I can sorta read your thoughts.',
                'Oh no, he\'s dying. That is super sad',
                'He wanted me to have this CD?',
                'That bastard is still trying to sell his',
                'demo tape even on his death bed.',
                'Tell him I\'ll take it but will probably never listen to it.',
            ],
        },
        2: {
            text: [
                'Well? Did you tell her? Was she super happy?',
                'Oh she said she\'ll take it?',
                'Well, at least I can die knowing I was unloved.',
            ],
            completedText: [
                'Farewell adventurer, this may be the last time we meet.',
            ],
        },
    }
} as const;