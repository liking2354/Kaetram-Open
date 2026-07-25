export default {
    name: 'Royal Pet',
    description: 'The king needs your help with distributing the good news to the people of Kaetram.|The king has asked you personally, yes, you, to run a couple errands for him. You must deliver some stuff and whatnot. Actually why don\'t you go talk to him instead of reading this description and spoiling the surprise. By surprise I mean you have to run around the place doing stupid stuff, but whatever, who cares, that\'s why you signed up on this game didn\'t you. Or was it because you wanted to grind but your addiction to being a completionist leads you to complete these useless quests. Oh well, this description is long enough.',
    rewards: ["A cute little pet kitty"],
    stages: {
        0: {
            text: [
                'Hello fellow idiot, I mean adventurer.',
                'I must distribute the good news to the residents of Kaetram',
                'I have all these books that I must hand out. Would you be so kind',
                'as to deliver these to some of Kaetram\'s residents.',
                'There should be a couple located throughout the city and in the swamp.',
            ],
            completedText: [
                'Please deliver the books to residents of Kaetram. They\'re located',
                'throughout the city and in the swamp.',
            ],
        },
        2: {
            text: [
                'Thank you for delivering the books adventurer.',
                'I have a special reward for you.',
                'I have this cute little kitty that I want to give to you.',
                'I hope you enjoy it.',
            ],
        },
    }
} as const;