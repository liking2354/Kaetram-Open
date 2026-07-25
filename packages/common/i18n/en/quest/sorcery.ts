export default {
    name: 'Sorcery and Stuff',
    description:
        'Learn the basics to sorcery|The sorcerer needs your help to re-assemble a long-lost magic staff that he lost on the beach. Help him out and perhaps he may teach you a thing or two about sorcery and stuff.',
    rewards: ['A Magic Staff', "Access to Sorcerer's store"],
    stages: {
        0: {
            text: [
                "Oh dear adventurer, it's you! One of the thousands",
                "I've trained and definitely not someone I don't remember.",
                "Listen, I'm on vacation here and was relaxing on the beach",
                'when all of the sudden I lost my entire magic contrband!',
                "I can't run a business if I don't have my equipment.",
                "Tell you what, if you bring me back 3 magic beads, I'll",
                'grant you access to my shop!',
                "You'll be taught how to",
                'craft your own magic staffs!'
            ],
            completedText: [
                'Please bring me 3 magic beads.',
                'If I recall correctly, some big macho crab took it',
                'and then retreated in a cave west of here.'
            ]
        },
        1: {
            hasItemText: ['Perfect, just perfect. These will surely be great.']
        }
    }
} as const;
