export default {
    name: 'Foresting',
    description:
        "Help the forester with foresting stuff.|The forester needs your help with foresting-related things such as trees and axes and stuff like that. I don't know I'm just a quest description stop asking me questions.",
    rewards: ['A Rusted Axe', "Access to Forester's store"],
    stages: {
        0: {
            text: [
                'Greetings dear adventurer!',
                'Please, you must help me.',
                "I simply cannot take it much longer, I've been",
                'cutting trees for the past few days.',
                "I'm rather exhausted, would you be so kind as",
                'to bring me 10 logs?'
            ],
            completedText: ['Please adventurer, bring me 10 logs.', "That's all I ask from you!"]
        },
        1: {
            completedText: ['Please adventurer, I beg of you, just 10 more logs.'],
            hasItemText: [
                'Oh my, dear adventurer',
                'These logs seem to have too many imperfections in them',
                'Would you be so kind as to bring me another 10?'
            ]
        },
        2: {
            hasItemText: [
                'Ah yes, you see, these logs are suitable for my needs.',
                'Thank you so much dear adventurer. Please take this reward!'
            ]
        }
    }
} as const;
