export default {
    name: 'Sea Activities',
    description: 'A mysterious being needs your help under the sea.|Venture under the sea by unlocking a secret entrance on the beach and talk to a fishy being about some underwater sea activities. If I remember correctly he may need your help with something.',
    rewards: ["1000 gold"],
    stages: {
        0: {
            text: [
                'HELP ME PLEASE!',
                'THE EVIL SEA CUCUMBER STOLE MY MONEY',
                'I SWEAR!',
                'PLEASE HE WENT SOMEWHERE SOUTH OF HERE',
                'FIND HIM PLEASE AND GET MY MONEY BACK!',
            ],
            completedText: [
                'FIND THE SEA CUCUMBER PLEASE!',
            ],
        },
        1: {
            text: [
                'Wait why are you here in my house?',
                'Is it about that stupid sponge?',
                'Listen man, I only took his money because he owed me',
                'a lot of money for the last 10 years.',
                'I\'m not giving it back.',
                'Now get out of my house.',
            ],
            completedText: [
                'I said I\'m not giving it back, now beat it.',
            ],
        },
        2: {
            text: [
                'Did you get my money back?',
                'He doesn\'t want to give it back?',
                'Tell that stupid cucumber to give it back or else!',
            ],
            completedText: [
                'Go tell him to give me my money back!',
            ],
        },
        3: {
            text: [
                'Okay you know what, I asked you to leave my house',
                'if you don\'t want to do that, then I\'ll have to fight you.',
                'I\'ll meet you in my personal arena then.',
            ],
            completedText: [
                'Go through the door and fight me fair and square!',
            ],
        },
        5: {
            text: [
                'All right all right. You win, I\'ll give that stupid sponge his gold.',
                'Here, now get out of here and leave me alone.',
            ],
        },
        6: {
            hasItemText: [
                'Thank you adventurer! With this gold I can finally buy a new house!',
                'Just you look at me, Mr. Sponge, homeowner!',
            ],
        },
    }
} as const;