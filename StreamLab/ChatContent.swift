import Foundation

/// One conversation seed. The ENGINE decides who speaks, when, and to whom.
/// openers: said by ONE viewer to start the topic (chat-wide, not addressed to the host unless natural).
/// answers: each said by a DIFFERENT viewer replying to the opener. Every answer must stand alone as a reply to ANY opener variant of this topic, and must not depend on any other answer.
/// followUps: something the original opener may say later, after some answers arrived. Must fit regardless of which answers came. May be empty.
/// hostKeywords: lowercase single words; if the HOST types a question containing one of these, `answers` are suitable replies to the host's question too.
struct ChatTopic {
    let id: String
    let scenes: [String]
    let openers: [String]
    let answers: [String]
    let followUps: [String]
    let hostKeywords: [String]
}

enum ChatContent {
    static let topics: [ChatTopic] = general + justChatting + gaming + challenge + cooking + outdoors + music + study

    // MARK: - General topics (any scene)

    private static let general: [ChatTopic] = generalA + generalB

    private static let generalA: [ChatTopic] = [
        ChatTopic(
            id: "any.drinks",
            scenes: ["any"],
            openers: ["what's everyone drinking rn", "drink check, what we got", "what's in your cup right now"],
            answers: [
                "water, being responsible",
                "green tea",
                "coffee at 11pm, great decision",
                "orange juice from the carton dont judge",
                "nothing, i should get up",
                "sparkling water",
                "hot chocolate",
                "energy drink, already regretting it",
                "milk lol",
                "cold brew from this morning, still going",
                "lemonade",
                "some herbal tea my sister left here",
                "flat soda that's been open since tuesday"
            ],
            followUps: ["coffee people are built different", "ok i'm getting tea now"],
            hostKeywords: ["drink", "drinking", "coffee", "tea", "water", "thirsty"]
        ),
        ChatTopic(
            id: "any.snacks",
            scenes: ["any"],
            openers: ["snack check, what's everyone eating", "anyone else snacking right now", "need snack ideas, what are you all having"],
            answers: [
                "popcorn",
                "pretzels",
                "apple slices, trying to be good",
                "chips, probably the whole bag",
                "nothing and now i'm hungry",
                "cheese straight from the fridge",
                "leftover pizza",
                "dry cereal out of the box",
                "gummy bears",
                "peanut butter on a spoon",
                "crackers",
                "frozen grapes, try it",
                "a granola bar that's mostly chocolate"
            ],
            followUps: ["ok raiding the kitchen", "i should not have asked, now i'm starving"],
            hostKeywords: ["snack", "snacks", "eating", "hungry", "chips"]
        ),
        ChatTopic(
            id: "any.sleep",
            scenes: ["any"],
            openers: ["what time does everyone usually go to bed", "sleep schedule check", "who here actually sleeps 8 hours"],
            answers: [
                "around 11 if i'm lucky",
                "2am on a good night",
                "what's a sleep schedule",
                "10pm, i'm old",
                "depends how interesting my phone is that night",
                "i work nights so i'm wide awake",
                "went to bed at 9 yesterday and still woke up tired",
                "never before midnight",
                "i nap instead lol",
                "midnight on the dot, weirdly consistent",
                "i keep saying i'll fix it",
                "6 hours max, every night",
                "whenever the cat lets me"
            ],
            followUps: ["glad i'm not the only one", "ok none of us are doing well"],
            hostKeywords: ["sleep", "bed", "bedtime", "tired", "nap", "sleeping"]
        ),
        ChatTopic(
            id: "any.weekend",
            scenes: ["any"],
            openers: ["anyone got weekend plans", "what's everyone doing this weekend", "weekend plans or just vibing"],
            answers: [
                "absolutely nothing and i'm excited",
                "working both days unfortunately",
                "family birthday thing",
                "laundry. that's the plan",
                "going on a hike if it doesn't rain",
                "helping a friend move, pray for me",
                "sleeping in",
                "probably gaming all weekend",
                "finally cleaning my apartment",
                "small trip out of town",
                "seeing a movie i think",
                "farmers market saturday morning",
                "what weekend, i work retail"
            ],
            followUps: ["sounds like everyone's busier than me", "i should make plans honestly"],
            hostKeywords: ["weekend", "saturday", "sunday", "plans", "friday"]
        ),
        ChatTopic(
            id: "any.pets",
            scenes: ["any"],
            openers: ["who has pets at home", "pet owners where you at", "anyone got a cat or dog with them rn"],
            answers: [
                "two cats, both asleep on me",
                "a dog who's staring at me for food",
                "no pets, my building doesn't allow them",
                "one old cat, she's 16",
                "a fish, he's fine",
                "no pets but i want a dog so bad",
                "my roommate's cat counts right?",
                "a bunny that chews everything",
                "allergic so no",
                "three dogs, it's loud here",
                "a gecko",
                "my parents' dog when i visit",
                "cat currently knocking stuff off my desk"
            ],
            followUps: ["everyone's pets sound better behaved than mine", "i want all of them honestly"],
            hostKeywords: ["pet", "pets", "cat", "dog", "cats", "dogs", "animal"]
        ),
        ChatTopic(
            id: "any.timezone",
            scenes: ["any"],
            openers: ["what time is it for everyone", "time check, where's everyone at", "how late is it for you all"],
            answers: [
                "almost midnight here",
                "3am, don't ask",
                "it's lunch time for me",
                "7pm, just ate",
                "early morning, on my first coffee",
                "like 4 in the afternoon",
                "9pm",
                "it's 1am and i have work at 8",
                "mid-afternoon, avoiding emails",
                "half past 10",
                "sunrise soon over here",
                "late enough that i should be asleep"
            ],
            followUps: ["chat is literally all over the place", "the 3am people need to sleep"],
            hostKeywords: ["time", "timezone", "late", "clock", "hour"]
        ),
        ChatTopic(
            id: "any.workmusic",
            scenes: ["any"],
            openers: ["do you guys listen to music while working", "music or silence when you work", "what do you put on when you need to get stuff done"],
            answers: [
                "lofi, every time",
                "silence or i can't think",
                "same playlist for like 3 years",
                "podcasts, but then i stop working",
                "video game soundtracks",
                "rain sounds",
                "loud rock, somehow helps",
                "whatever the radio has on",
                "classical, makes me feel smart",
                "streams in the background tbh",
                "white noise",
                "only music without words",
                "i sing along so no work gets done"
            ],
            followUps: ["ok gonna try something new tomorrow", "silence people are stronger than me"],
            hostKeywords: ["music", "playlist", "listen", "listening", "songs"]
        ),
        ChatTopic(
            id: "any.battery",
            scenes: ["any"],
            openers: ["battery check, what's your phone at", "whose phone is dying right now", "phone battery percentage go"],
            answers: [
                "12% and no charger nearby",
                "100, plugged in all day",
                "63",
                "4%, living dangerously",
                "40 but it's an old phone so basically 10",
                "charging right now",
                "88",
                "mine died an hour ago, on laptop now",
                "21, should be fine",
                "always under 20, it's a lifestyle",
                "my battery health is at 74 so who knows",
                "half"
            ],
            followUps: ["someone go charge their phone", "i'm at 9 btw"],
            hostKeywords: ["battery", "phone", "charge", "charger", "charging", "percent"]
        ),
        ChatTopic(
            id: "any.weather",
            scenes: ["any"],
            openers: ["how's the weather where you are", "weather check from chat", "is it nice out where you are"],
            answers: [
                "raining nonstop here",
                "super hot, fan on full",
                "cold, finally sweater season",
                "snow already somehow",
                "sunny but windy",
                "foggy all day",
                "humid, everything is sticky",
                "perfect actually, like 20 degrees",
                "thunderstorm right now",
                "grey and boring",
                "can't tell, haven't been outside",
                "cold in the morning, hot by noon",
                "dry and dusty"
            ],
            followUps: ["chat has every season at once", "i want to live where the nice weather is"],
            hostKeywords: ["weather", "rain", "raining", "cold", "hot", "snow", "sunny"]
        ),
        ChatTopic(
            id: "any.shows",
            scenes: ["any"],
            openers: ["anyone watching a good show right now", "what shows are you all watching", "need something to binge, what are you watching"],
            answers: [
                "rewatching an old sitcom for the 5th time",
                "a cooking competition show",
                "nothing, can't pick anything",
                "a true crime doc, bad idea at night",
                "anime mostly",
                "a baking show with my mom",
                "some fantasy series, it's ok",
                "just streams honestly",
                "reality tv, no shame",
                "a nature doc, very calming",
                "a medical drama i'm way too invested in",
                "three shows at once and finishing none",
                "old cartoons"
            ],
            followUps: ["everyone rewatches the same comfort show huh", "my watchlist just got longer"],
            hostKeywords: ["show", "shows", "series", "binge", "tv", "netflix"]
        ),
        ChatTopic(
            id: "any.commute",
            scenes: ["any"],
            openers: ["how does everyone get to work or school", "commute check", "anyone here have a long commute"],
            answers: [
                "walk, 10 minutes",
                "train, an hour each way",
                "bike when it's not raining",
                "work from home, my commute is the hallway",
                "bus, always late",
                "drive, the traffic is awful",
                "scooter",
                "my dad drives me",
                "carpool with a coworker",
                "45 minutes on the subway",
                "don't have one right now",
                "two buses and a walk"
            ],
            followUps: ["long commutes should count as work hours", "remote people are winning"],
            hostKeywords: ["commute", "bus", "train", "drive", "traffic", "school"]
        ),
        ChatTopic(
            id: "any.comfortfood",
            scenes: ["any"],
            openers: ["what's your comfort food", "bad day food, what's yours", "go to food when you're sad?"],
            answers: [
                "mac and cheese",
                "ramen, the cheap kind",
                "my grandma's soup",
                "grilled cheese and tomato soup",
                "fries from anywhere",
                "rice with an egg on top",
                "ice cream straight from the tub",
                "dumplings",
                "pancakes at any hour",
                "mashed potatoes",
                "toast with butter, simple",
                "spicy noodles",
                "chicken nuggets, i'm a child"
            ],
            followUps: ["now i'm hungry, thanks chat", "nobody said salad lol"],
            hostKeywords: ["comfort", "favorite", "favourite", "dish", "food"]
        ),
        ChatTopic(
            id: "any.morningnight",
            scenes: ["any"],
            openers: ["morning person or night person", "early bird or night owl, chat", "are you a morning person"],
            answers: [
                "night, no question",
                "morning, i wake up at 6 without an alarm",
                "neither, i'm tired all day",
                "night owl stuck with a morning job",
                "used to be night, now i'm old",
                "morning but only with coffee",
                "night, my brain starts working at 10pm",
                "morning in summer, night in winter",
                "whatever gets me out of meetings",
                "night obviously, look at the time",
                "early bird since i got a dog",
                "i have no idea anymore"
            ],
            followUps: ["morning people are a mystery to me", "night owls stay winning"],
            hostKeywords: ["morning", "night", "early", "owl", "person"]
        ),
        ChatTopic(
            id: "any.dinner",
            scenes: ["any"],
            openers: ["what did everyone have for dinner", "dinner check", "anyone eat yet?"],
            answers: [
                "tacos",
                "cereal, it counts",
                "haven't eaten yet oops",
                "pasta again",
                "leftover curry",
                "a sandwich standing over the sink",
                "stir fry",
                "salad and then chips",
                "pizza delivery",
                "soup my roommate made",
                "just a banana so far",
                "burgers on the grill",
                "rice and beans"
            ],
            followUps: ["the people who haven't eaten, go eat", "ok i'm ordering something"],
            hostKeywords: ["dinner", "eat", "ate", "lunch", "meal"]
        )
    ]

    private static let generalB: [ChatTopic] = [
        ChatTopic(
            id: "any.dayrating",
            scenes: ["any"],
            openers: ["how was everyone's day", "rate your day out of 10", "good day or bad day chat"],
            answers: [
                "6, nothing happened",
                "honestly a 9, got a lot done",
                "3, my car wouldn't start",
                "a solid 7",
                "long day, glad it's over",
                "it was fine, kinda boring",
                "great, i slept in",
                "bad day but better now",
                "5, work was work",
                "8 because i had pizza",
                "it's still going unfortunately",
                "survived, that's all i got"
            ],
            followUps: ["hope tomorrow's better for the low numbers", "pretty average day for me too"],
            hostKeywords: ["day", "today", "rate", "week"]
        ),
        ChatTopic(
            id: "any.hobbies",
            scenes: ["any"],
            openers: ["what hobbies do you all have outside of this", "anyone picked up a new hobby lately", "hobby check"],
            answers: [
                "rock climbing, badly",
                "knitting, started last winter",
                "i collect old cameras",
                "running, slowly",
                "baking bread",
                "board games with friends",
                "drawing but i never finish anything",
                "fishing with my dad",
                "gardening on a tiny balcony",
                "learning guitar for the third time",
                "does sleeping count",
                "puzzles, 1000 pieces minimum",
                "building model kits"
            ],
            followUps: ["i really need a hobby that isn't my phone", "everyone's more interesting than me"],
            hostKeywords: ["hobby", "hobbies", "free", "fun", "interests", "spare"]
        ),
        ChatTopic(
            id: "any.reading",
            scenes: ["any"],
            openers: ["anyone reading anything good", "book people in chat?", "last book you finished?"],
            answers: [
                "a fantasy series, on book 4",
                "haven't read a book in years tbh",
                "a mystery novel, can't put it down",
                "audiobooks on my commute",
                "comics mostly",
                "a cookbook, does that count",
                "rereading something from high school",
                "manga",
                "a biography, slowly",
                "started three, finished none",
                "sci-fi, always",
                "whatever my book club picks",
                "i read before bed and fall asleep in 2 pages"
            ],
            followUps: ["my reading list is getting out of hand", "ok i'll pick a book back up this week"],
            hostKeywords: ["book", "books", "reading", "read", "novel", "library"]
        ),
        ChatTopic(
            id: "any.chores",
            scenes: ["any"],
            openers: ["which chore do you hate most", "worst chore, go", "what chore are you avoiding right now"],
            answers: [
                "dishes, every time",
                "folding laundry",
                "cleaning the bathroom",
                "vacuuming, my vacuum is so loud",
                "taking out the trash in the rain",
                "putting laundry away, it lives on a chair",
                "i don't mind any of them weirdly",
                "mopping",
                "unloading the dishwasher",
                "cleaning out the fridge",
                "ironing, i just don't",
                "making the bed, what's the point",
                "scrubbing the oven"
            ],
            followUps: ["i have a sink full of dishes right now so", "chores are just never done huh"],
            hostKeywords: ["chore", "chores", "laundry", "vacuum", "housework"]
        ),
        ChatTopic(
            id: "any.foodtakes",
            scenes: ["any"],
            openers: ["unpopular food opinion, go", "food hot take?", "what food does everyone like that you don't"],
            answers: [
                "pineapple on pizza is good, sorry",
                "avocado is overrated",
                "i don't like chocolate much",
                "ketchup on eggs",
                "cold pizza beats hot pizza",
                "mayo is gross",
                "sushi isn't that great",
                "cereal is better without milk",
                "coffee tastes like dirt to me",
                "white chocolate is the best one",
                "i don't get the hype around bacon",
                "burnt toast is fine",
                "peanut butter and pickles works"
            ],
            followUps: ["some of these are crimes", "ok i expected worse"],
            hostKeywords: ["opinion", "unpopular", "overrated", "underrated", "take"]
        ),
        ChatTopic(
            id: "any.device",
            scenes: ["any"],
            openers: ["what's everyone watching on, phone or pc", "who's watching on their phone", "tv, phone, or laptop crew"],
            answers: [
                "phone in bed",
                "pc, second monitor",
                "tv, lying on the couch",
                "laptop at work, shh",
                "tablet propped on a pillow",
                "phone on the bus",
                "pc, game paused in the other window",
                "phone with the brightness way down",
                "laptop on my kitchen table",
                "my brother's laptop",
                "on my phone while cooking",
                "tv through a console"
            ],
            followUps: ["i'm on my phone too", "the second monitor setup is the dream"],
            hostKeywords: ["device", "pc", "laptop", "tablet", "mobile", "watching"]
        ),
        ChatTopic(
            id: "any.seasons",
            scenes: ["any"],
            openers: ["favorite season?", "best season, go", "summer or winter people?"],
            answers: [
                "autumn, easy",
                "winter, i like the cold",
                "summer, beach every weekend",
                "spring but my allergies say no",
                "fall for the hoodies",
                "summer nights specifically",
                "winter holidays, not winter itself",
                "none, i like being inside",
                "spring, everything smells nice",
                "late autumn when it gets dark early",
                "summer, i hate being cold",
                "whichever one has the least bugs"
            ],
            followUps: ["fall people are always the loudest", "everyone's right honestly"],
            hostKeywords: ["season", "seasons", "summer", "winter", "fall", "autumn", "spring"]
        ),
        ChatTopic(
            id: "any.stillworking",
            scenes: ["any"],
            openers: ["anyone else still at work", "who's on shift right now", "anyone watching from work lol"],
            answers: [
                "night shift, 4 more hours",
                "yep, on break",
                "done for the day finally",
                "working from home so technically",
                "on lunch",
                "i'm the only one in the office",
                "student, no job, just homework",
                "just clocked out",
                "on mute at my desk",
                "security job, very quiet night",
                "between jobs, i have all the time",
                "about to start a shift actually"
            ],
            followUps: ["the night shift people are heroes", "hang in there workers"],
            hostKeywords: ["work", "job", "shift", "office", "working", "boss"]
        ),
        ChatTopic(
            id: "any.breakfast",
            scenes: ["any"],
            openers: ["do you eat breakfast or skip it", "breakfast people?", "what's a normal breakfast for you"],
            answers: [
                "coffee is breakfast",
                "eggs and toast every day",
                "oatmeal with too much sugar",
                "skip it, not hungry till noon",
                "a bowl of cereal, same brand forever",
                "yogurt and fruit",
                "whatever's left from dinner",
                "a protein bar in the car",
                "full breakfast on weekends only",
                "bagel with cream cheese",
                "smoothie",
                "i eat breakfast at 2pm, does that count"
            ],
            followUps: ["breakfast skippers worry me", "i'm hungry again"],
            hostKeywords: ["breakfast", "eggs", "cereal", "oatmeal", "brunch"]
        ),
        ChatTopic(
            id: "any.travel",
            scenes: ["any"],
            openers: ["where's somewhere you want to travel", "dream trip, where to", "anyone been anywhere cool lately"],
            answers: [
                "somewhere with mountains",
                "anywhere with a beach",
                "a road trip with no plan",
                "somewhere cold enough to see northern lights",
                "visiting family overseas",
                "never been on a plane actually",
                "a big city i've never seen",
                "a cabin in the woods, no wifi",
                "anywhere with good street food",
                "back to where i grew up",
                "an island somewhere quiet",
                "a long train trip across the country"
            ],
            followUps: ["i need a vacation so bad", "adding all of these to my list"],
            hostKeywords: ["travel", "trip", "vacation", "visit", "holiday", "country"]
        ),
        ChatTopic(
            id: "any.childhood",
            scenes: ["any"],
            openers: ["what did you watch as a kid", "favorite cartoon growing up?", "what show were you obsessed with as a kid"],
            answers: [
                "saturday morning cartoons, all of them",
                "a nature show about animals",
                "some anime that aired after school",
                "whatever my older brother picked",
                "the weather channel, weirdly",
                "a puppet show i barely remember",
                "superhero cartoons",
                "a show about a kid detective",
                "we didn't have tv so books",
                "game shows with my grandpa",
                "old movies on vhs",
                "a cooking show, i was a weird kid"
            ],
            followUps: ["the old stuff hits different", "i forgot about half of this"],
            hostKeywords: ["kid", "childhood", "cartoon", "cartoons", "grew", "growing"]
        ),
        ChatTopic(
            id: "any.alarm",
            scenes: ["any"],
            openers: ["do you snooze your alarm", "how many alarms do you set", "alarm people, one or ten?"],
            answers: [
                "one alarm, up immediately",
                "five alarms 5 minutes apart",
                "snooze at least three times",
                "no alarm, i just wake up",
                "my dog is my alarm",
                "phone across the room so i have to get up",
                "i sleep through all of them",
                "two, the second one is for panic",
                "a sunrise lamp",
                "i turn it off in my sleep and don't remember",
                "never use one, don't have to be anywhere",
                "my neighbor's car alarm"
            ],
            followUps: ["the multi alarm people need help", "snoozing is a lifestyle"],
            hostKeywords: ["alarm", "alarms", "snooze", "wake", "waking"]
        ),
        ChatTopic(
            id: "any.plants",
            scenes: ["any"],
            openers: ["anyone have houseplants", "plant people in chat?", "how are your plants doing"],
            answers: [
                "i kill every plant i touch",
                "like 30, it's a jungle",
                "one cactus, thriving",
                "fake plants only now",
                "a basil plant i keep forgetting to water",
                "my mom gives me hers to keep alive",
                "a big leafy one in the corner",
                "succulents, they still died",
                "tomatoes on the balcony",
                "none, my cat eats them",
                "a plant i've had since college",
                "herbs in the kitchen window"
            ],
            followUps: ["ok i need to water mine", "plants are harder than they look"],
            hostKeywords: ["plant", "plants", "garden", "gardening", "cactus"]
        ),
        ChatTopic(
            id: "any.talent",
            scenes: ["any"],
            openers: ["what's a useless skill you have", "weird talent check", "anyone got a random party trick"],
            answers: [
                "i can wiggle my ears",
                "i know every country's flag",
                "i can fall asleep anywhere instantly",
                "whistling really loud",
                "i can name a song in 2 seconds",
                "typing without looking",
                "touching my nose with my tongue",
                "i can juggle three things",
                "remembering everyone's birthday",
                "i can fold a fitted sheet",
                "nothing, i'm boring",
                "a decent duck call",
                "solving a rubik's cube, slowly"
            ],
            followUps: ["these are better than mine", "i can't do any of these"],
            hostKeywords: ["skill", "talent", "trick", "useless", "weird"]
        )
    ]

    // MARK: - Just chatting

    private static let justChatting: [ChatTopic] = [
        ChatTopic(
            id: "jc.lastbuy",
            scenes: ["Just chatting"],
            openers: ["what's the last thing you bought", "last purchase, no lying", "what did you buy most recently"],
            answers: [
                "groceries, boring",
                "new socks",
                "a lamp i didn't need",
                "a game on sale i won't play",
                "coffee this morning",
                "a phone case",
                "concert tickets",
                "dog food",
                "a plant, it's already sad",
                "bus pass",
                "a birthday gift for my sister",
                "batteries",
                "fancy shampoo, treated myself"
            ],
            followUps: ["my last one was cat litter so", "i always buy stuff i don't need"],
            hostKeywords: ["bought", "buy", "purchase", "shopping", "spent"]
        ),
        ChatTopic(
            id: "jc.firstjob",
            scenes: ["Just chatting"],
            openers: ["what was your first job", "first job stories?", "anyone remember their first paycheck"],
            answers: [
                "fast food, the fryer still haunts me",
                "babysitting",
                "lifeguard at a pool",
                "stocking shelves at night",
                "paper route",
                "cashier at a grocery store",
                "walking dogs in my neighborhood",
                "summer camp counselor",
                "dishwasher at a diner",
                "never had one yet",
                "movie theater, free popcorn",
                "mowing lawns",
                "tutoring kids in math"
            ],
            followUps: ["everyone's done food service at some point", "i spent my first paycheck on nothing useful"],
            hostKeywords: ["job", "first", "paycheck", "worked", "career"]
        ),
        ChatTopic(
            id: "jc.cityortown",
            scenes: ["Just chatting"],
            openers: ["city person or small town person", "do you live somewhere big or small", "city or countryside, chat"],
            answers: [
                "big city, it's loud",
                "small town, one traffic light",
                "suburbs, nothing to do",
                "farm, nearest store is 20 minutes away",
                "city now, grew up in a village",
                "medium town, the worst of both",
                "middle of nowhere and i love it",
                "big city but i never go out",
                "small town, everyone knows everyone",
                "moving to the city next year",
                "coastal town, very windy",
                "college town"
            ],
            followUps: ["small towns sound peaceful", "i'd love to live somewhere quieter"],
            hostKeywords: ["city", "town", "live", "countryside", "village", "suburbs"]
        ),
        ChatTopic(
            id: "jc.textcall",
            scenes: ["Just chatting"],
            openers: ["texting or calling, which do you prefer", "do you answer phone calls", "text people or call people?"],
            answers: [
                "text, always",
                "calls are faster honestly",
                "i let it ring and text back",
                "voice messages, sorry",
                "calls only with my mom",
                "text, calls give me anxiety",
                "video call or nothing",
                "call if it's important",
                "i reply 3 days later either way",
                "i like calls, texting is slow",
                "work stuff is text, family is calls",
                "never answer unknown numbers"
            ],
            followUps: ["i have 12 unread texts right now", "calls feel so official"],
            hostKeywords: ["text", "call", "calling", "texting", "message", "calls"]
        ),
        ChatTopic(
            id: "jc.social",
            scenes: ["Just chatting"],
            openers: ["introvert or extrovert, chat", "how's everyone's social battery", "people person or nah"],
            answers: [
                "introvert, this chat is enough socializing",
                "extrovert, i need people",
                "somewhere in the middle",
                "social battery at 5% after work",
                "i like people in small doses",
                "extrovert in the morning, introvert after 8",
                "full introvert, phone on silent",
                "i talk a lot online, not irl",
                "fully recharged, slept all day",
                "fine until a group gets bigger than 4",
                "depends on the people",
                "extrovert, being alone makes me weird"
            ],
            followUps: ["pretty much everyone here is an introvert lol", "same honestly"],
            hostKeywords: ["introvert", "extrovert", "social", "people", "shy"]
        ),
        ChatTopic(
            id: "jc.superpower",
            scenes: ["Just chatting"],
            openers: ["if you could have one superpower what would it be", "superpower pick, go", "random question, best superpower?"],
            answers: [
                "teleporting, no more commute",
                "never needing sleep",
                "flying, obviously",
                "invisibility, mind reading sounds stressful",
                "pause time",
                "talk to animals",
                "instantly learning any language",
                "super speed but only for chores",
                "eating anything and staying healthy",
                "healing people",
                "always finding parking",
                "unlimited phone battery"
            ],
            followUps: ["practical superpowers only i guess", "i'd still be late with teleporting"],
            hostKeywords: ["superpower", "power", "powers", "hero"]
        ),
        ChatTopic(
            id: "jc.learn",
            scenes: ["Just chatting"],
            openers: ["what's something you want to learn this year", "anyone learning something new", "skill you wish you had?"],
            answers: [
                "cooking real food",
                "a second language",
                "swimming, never learned",
                "drawing",
                "how to drive finally",
                "piano",
                "coding",
                "how to do a cartwheel lol",
                "sign language",
                "fixing my own bike",
                "photography",
                "sewing so i can fix my clothes",
                "how to relax"
            ],
            followUps: ["i keep starting things and stopping", "i want to learn all of these now"],
            hostKeywords: ["learn", "learning", "skill", "teach", "goal"]
        )
    ]

    // MARK: - Late night gaming

    private static let gaming: [ChatTopic] = [
        ChatTopic(
            id: "gm.controller",
            scenes: ["Late night gaming"],
            openers: ["controller or keyboard and mouse", "controller people vs mouse people", "what does everyone play on, pad or keyboard"],
            answers: [
                "mouse and keyboard, no contest",
                "controller, i'm lazy",
                "controller for most things, mouse for shooters",
                "controller on the couch every time",
                "keyboard, my controller has drift",
                "whatever the game feels best with",
                "mouse, i can't aim with sticks",
                "steering wheel for racing games",
                "controller since i was a kid",
                "laptop trackpad, don't ask",
                "controller with back paddles",
                "fight stick for fighting games"
            ],
            followUps: ["this argument never ends", "i switch depending on my mood"],
            hostKeywords: ["controller", "keyboard", "mouse", "pad", "gamepad"]
        ),
        ChatTopic(
            id: "gm.backlog",
            scenes: ["Late night gaming"],
            openers: ["how big is everyone's game backlog", "backlog check, how bad is it", "how many games do you own and never played"],
            answers: [
                "like 200, mostly from sales",
                "zero, i finish everything",
                "three, which is manageable",
                "i don't want to count",
                "i only replay the same two games",
                "over 50 and i keep buying more",
                "i played the first hour of all of them",
                "my backlog has a backlog",
                "i keep a list, it's long",
                "only a few, i don't buy much",
                "i finally beat one last week",
                "free games i grabbed and forgot about"
            ],
            followUps: ["sales are the problem honestly", "i'm probably adding to mine right now"],
            hostKeywords: ["backlog", "games", "sale", "finish", "unplayed", "library"]
        ),
        ChatTopic(
            id: "gm.settings",
            scenes: ["Late night gaming"],
            openers: ["what's the first setting you change in a new game", "settings check, what do you always change", "anyone else spend 20 minutes in the options menu"],
            answers: [
                "turn off motion blur immediately",
                "invert y axis, sorry",
                "subtitles on always",
                "lower the music volume",
                "sensitivity, every time",
                "turn off film grain",
                "brightness way up",
                "nothing, i play on default",
                "field of view all the way up",
                "turn off camera shake",
                "remap jump, every time",
                "colorblind mode actually helps me",
                "turn off the tutorial popups if i can"
            ],
            followUps: ["motion blur is the enemy", "default settings people are brave"],
            hostKeywords: ["settings", "setting", "options", "sensitivity", "blur", "graphics"]
        ),
        ChatTopic(
            id: "gm.rage",
            scenes: ["Late night gaming"],
            openers: ["has anyone actually broken something from gaming rage", "rage check, worst you've done", "what makes you rage quit"],
            answers: [
                "snapped a controller in half once",
                "i just go quiet when i'm mad",
                "laggy servers, every time",
                "teammates who don't listen",
                "threw a controller at my bed and it bounced off",
                "never rage, i just turn it off and stare",
                "missing a jump i've done a hundred times",
                "unskippable cutscenes before a hard part",
                "i yell at the screen but that's it",
                "losing progress to a crash",
                "escort missions",
                "dying to the same thing twice in a row"
            ],
            followUps: ["ok so it's not just me who yells", "crashes are the worst one"],
            hostKeywords: ["rage", "quit", "angry", "mad", "tilt", "tilted"]
        ),
        ChatTopic(
            id: "gm.snacks",
            scenes: ["Late night gaming"],
            openers: ["best snack for gaming", "what are you eating while you play", "gaming snack tier list, go"],
            answers: [
                "chips with chopsticks, keeps the controller clean",
                "nothing, i forget to eat",
                "gummy candy",
                "popcorn but it gets everywhere",
                "a whole pizza",
                "nuts, no crumbs",
                "sour candy, the really sour kind",
                "grapes",
                "chocolate, one piece at a time",
                "pretzel sticks",
                "cold leftovers straight from the container",
                "cookies",
                "string cheese"
            ],
            followUps: ["greasy fingers on the keyboard is the worst", "getting snacks after this round"],
            hostKeywords: ["snack", "snacks", "eat", "hungry", "food"]
        ),
        ChatTopic(
            id: "gm.latenight",
            scenes: ["Late night gaming"],
            openers: ["latest you've ever stayed up gaming", "who else is gaming way past bedtime", "how late do you usually play"],
            answers: [
                "sunrise once, never again",
                "midnight is my limit now",
                "4am on a work night, regretted it",
                "i fall asleep with the controller",
                "all nighter for a launch day",
                "only late on weekends",
                "2am is normal for me",
                "i play in the morning actually",
                "until my eyes hurt",
                "my partner makes me stop at 1",
                "until the controller battery dies",
                "never past 11, i need sleep"
            ],
            followUps: ["one more match always turns into ten", "we all need sleep huh"],
            hostKeywords: ["late", "stay", "bedtime", "allnighter", "night"]
        ),
        ChatTopic(
            id: "gm.genre",
            scenes: ["Late night gaming"],
            openers: ["what kind of games do you play most", "favorite genre?", "rpg people, shooter people, what are we"],
            answers: [
                "rpgs, the longer the better",
                "shooters with friends",
                "cozy farming games",
                "puzzle games",
                "horror, alone with headphones",
                "strategy, i like thinking slow",
                "racing",
                "platformers",
                "sports games, same one every year",
                "roguelikes, one more run forever",
                "open world, i never do the story",
                "fighting games",
                "whatever my friends are playing"
            ],
            followUps: ["cozy games at night are perfect", "i play basically everything"],
            hostKeywords: ["genre", "rpg", "shooter", "kind", "type", "favorite"]
        )
    ]

    // MARK: - One more attempt

    private static let challenge: [ChatTopic] = [
        ChatTopic(
            id: "ch.attempts",
            scenes: ["One more attempt"],
            openers: ["most attempts you've ever put into one thing", "what's your record for retrying something", "anyone else stubborn about beating stuff"],
            answers: [
                "like 300 tries on one level once",
                "i give up after 10",
                "a driving test, three times",
                "took me a whole weekend once",
                "i lose count after 50",
                "still haven't done it, years later",
                "kickflip, about a month",
                "i'd rather watch someone else do it",
                "solved a puzzle box after weeks",
                "probably 80 tries and then it just worked",
                "i don't retry things, i move on",
                "baking bread, attempt 12 was finally good"
            ],
            followUps: ["stubborn is a personality trait at this point", "ok i feel better about my attempts now"],
            hostKeywords: ["attempts", "attempt", "tries", "try", "retry", "record"]
        ),
        ChatTopic(
            id: "ch.patience",
            scenes: ["One more attempt"],
            openers: ["how patient are you when stuff keeps going wrong", "patience check, how are we doing", "what's your patience like, honestly"],
            answers: [
                "zero patience, i walk away",
                "very patient until i'm suddenly not",
                "i get calmer the more i fail weirdly",
                "i need a snack break every 20 minutes",
                "pretty good, i fish",
                "terrible, i yell at printers",
                "only patient with other people, not myself",
                "i count to ten, it doesn't work",
                "more patient than i used to be",
                "depends if i slept",
                "patient with games, not with traffic",
                "none left today, sorry"
            ],
            followUps: ["walking away works for me sometimes", "patience is overrated anyway"],
            hostKeywords: ["patience", "patient", "calm", "frustrated", "annoying"]
        ),
        ChatTopic(
            id: "ch.warmup",
            scenes: ["One more attempt"],
            openers: ["do you warm up before trying something hard", "warmup or go straight in?", "anyone have a warmup routine"],
            answers: [
                "straight in, no warmup",
                "10 minutes of easy stuff first",
                "i stretch my hands, sounds silly but works",
                "my warmup is the first 5 failed attempts",
                "same practice drill every time",
                "coffee is my warmup",
                "i watch a run first to remember it",
                "never, and it shows",
                "a short walk to clear my head",
                "i play something easy for a bit",
                "my warmup takes longer than the real thing",
                "only when it matters"
            ],
            followUps: ["i should warm up more honestly", "skipping it every time anyway"],
            hostKeywords: ["warmup", "warm", "routine", "ready", "stretch"]
        ),
        ChatTopic(
            id: "ch.breaks",
            scenes: ["One more attempt"],
            openers: ["do you take breaks or grind until it works", "break or keep going?", "how long before you need a break when it's not working"],
            answers: [
                "grind, i'm too stubborn",
                "break every hour, set a timer",
                "i stop when i get angry",
                "walk away for 5 and it works first try",
                "keep going, momentum matters",
                "i sleep on it and come back",
                "break when my hands get sweaty",
                "every 20 attempts i get water",
                "never take breaks, then i'm done for a week",
                "i switch to something else and come back",
                "only for food",
                "when i start making new mistakes i stop"
            ],
            followUps: ["breaks always seem to help me", "i never take them and i should"],
            hostKeywords: ["break", "breaks", "grind", "rest", "keep"]
        ),
        ChatTopic(
            id: "ch.ritual",
            scenes: ["One more attempt"],
            openers: ["anyone have a lucky ritual before a big attempt", "lucky habits? socks, snacks, anything", "superstitions when you really need it to work"],
            answers: [
                "same hoodie every time",
                "i don't look at the timer",
                "deep breath and crack my knuckles",
                "i say out loud that it won't work",
                "lucky socks, yes really",
                "i don't talk to anyone right before",
                "no rituals, just vibes",
                "i sit on the edge of my chair",
                "i drink water first, every time",
                "turn the lights down",
                "i don't believe in luck but i still knock on wood",
                "i stop chewing gum, don't know why"
            ],
            followUps: ["everyone has one even if they deny it", "mine is not saying anything until it's done"],
            hostKeywords: ["lucky", "luck", "ritual", "superstition", "superstitious", "jinx"]
        ),
        ChatTopic(
            id: "ch.quit",
            scenes: ["One more attempt"],
            openers: ["when do you call it and stop for the day", "how do you know it's time to quit for today", "at what point do you give up on something"],
            answers: [
                "when i'm getting worse, not better",
                "after three bad tries in a row",
                "never, until it's done",
                "when it stops being fun",
                "when someone tells me to eat",
                "midnight is my hard stop",
                "when my hands start shaking",
                "i set a number of attempts beforehand",
                "i quit and then try one more anyway",
                "when my eyes hurt from the screen",
                "i don't stop, i just switch to something else",
                "when i start blaming everything but me"
            ],
            followUps: ["having a hard stop sounds healthy", "i never know when to stop honestly"],
            hostKeywords: ["quit", "stop", "give", "enough", "call"]
        ),
        ChatTopic(
            id: "ch.practice",
            scenes: ["One more attempt"],
            openers: ["how do you practice something hard", "practice method, slow or full speed?", "do you practice parts or the whole thing"],
            answers: [
                "just the hard part over and over",
                "full runs only, that's how i learn",
                "slow first, then speed up",
                "i record myself and watch it back",
                "short sessions every day",
                "until i get it right 3 times in a row",
                "i don't practice, i just play",
                "watching people better than me",
                "split it into pieces, then glue them together",
                "muscle memory, no thinking",
                "i write notes, nerd move",
                "practice the bit right before the hard part too"
            ],
            followUps: ["practice is boring but it works", "i never practice right honestly"],
            hostKeywords: ["practice", "practicing", "train", "method", "improve"]
        )
    ]

    // MARK: - Cooking & food

    private static let cooking: [ChatTopic] = [
        ChatTopic(
            id: "ck.cleanup",
            scenes: ["Cooking & food"],
            openers: ["clean as you go or clean after", "who does the dishes after cooking at your place", "cleanup while cooking or after?"],
            answers: [
                "clean as i go, can't stand the mess",
                "after, and then i regret it",
                "whoever didn't cook",
                "i leave it till morning",
                "dishwasher does everything",
                "i use one pan to avoid dishes",
                "my roommate, we have a deal",
                "clean as i go but only the knives",
                "i soak everything and forget about it",
                "after, with music on",
                "i cook simple stuff so there's barely anything",
                "paper plates, no shame"
            ],
            followUps: ["dishes are the worst part of cooking", "i have a pan soaking right now actually"],
            hostKeywords: ["clean", "cleanup", "dishes", "mess", "wash", "sink"]
        ),
        ChatTopic(
            id: "ck.spice",
            scenes: ["Cooking & food"],
            openers: ["how much spice can everyone handle", "spice tolerance check", "mild, medium, or hot?"],
            answers: [
                "mild, black pepper is spicy to me",
                "as hot as possible",
                "medium, i like to taste my food",
                "grew up on spicy food so pretty high",
                "i like it but my stomach doesn't",
                "hot sauce on everything",
                "zero, i'm weak",
                "medium but i pretend it's hot",
                "i keep chili flakes at my desk",
                "i can handle it but i cry",
                "a ghost pepper chip ruined my whole day once",
                "it changes, some days i can't do any"
            ],
            followUps: ["hot sauce people are scary", "i'm a medium person i think"],
            hostKeywords: ["spicy", "spice", "chili", "pepper", "mild", "sauce"]
        ),
        ChatTopic(
            id: "ck.disaster",
            scenes: ["Cooking & food"],
            openers: ["worst kitchen disaster you've had", "anyone ever set off the smoke alarm cooking", "kitchen fail stories?"],
            answers: [
                "burned rice so bad i threw out the pot",
                "smoke alarm every time i make toast",
                "forgot the sugar in a cake",
                "dropped a whole lasagna on the floor",
                "used salt instead of sugar",
                "melted a plastic spatula into the sauce",
                "exploded an egg in the microwave",
                "pasta boiled over and flooded the stove",
                "cut my finger on day one of a new knife",
                "set a towel on fire, it was fine",
                "baked cookies into one giant cookie",
                "never had one, i don't really cook"
            ],
            followUps: ["glad it's not just me", "my smoke alarm knows me personally"],
            hostKeywords: ["disaster", "burned", "burnt", "fire", "mistake", "smoke"]
        ),
        ChatTopic(
            id: "ck.recipe",
            scenes: ["Cooking & food"],
            openers: ["do you follow recipes or just wing it", "recipe people or vibes people", "measure stuff or eyeball it?"],
            answers: [
                "follow it exactly the first time",
                "wing it, always",
                "recipe for baking, vibes for everything else",
                "skim it once, then improvise",
                "eyeball everything, garlic especially",
                "i need the video, not the text",
                "my grandma's notebook only",
                "i scroll past the life story and hope",
                "measure everything, i'm nervous",
                "i combine three recipes into one",
                "i make the same five things",
                "the recipe is a suggestion"
            ],
            followUps: ["baking needs measuring though", "i'm a vibes cook and it shows"],
            hostKeywords: ["recipe", "recipes", "measure", "follow", "eyeball"]
        ),
        ChatTopic(
            id: "ck.leftovers",
            scenes: ["Cooking & food"],
            openers: ["leftovers, love them or hate them", "do you actually eat your leftovers", "best thing to eat as leftovers?"],
            answers: [
                "curry is better the next day",
                "i forget them until they're scary",
                "i put them in nice containers so i feel fancy",
                "i cook extra on purpose for lunch",
                "i hate reheated food",
                "fried rice made from old rice",
                "pasta, microwave, done",
                "my family fights over them",
                "soup, always better on day two",
                "only if someone else made it",
                "i freeze everything and never eat it",
                "tacos the next day hit different"
            ],
            followUps: ["the next day thing is real", "i have some in the fridge right now"],
            hostKeywords: ["leftovers", "leftover", "reheat", "fridge", "microwave"]
        ),
        ChatTopic(
            id: "ck.tool",
            scenes: ["Cooking & food"],
            openers: ["what kitchen tool do you use the most", "one kitchen tool you can't live without", "most useful thing in your kitchen?"],
            answers: [
                "a good knife, nothing else matters",
                "rice cooker",
                "air fryer, don't judge",
                "a big cast iron pan",
                "my microwave, honestly",
                "kitchen scissors",
                "wooden spoon from my grandma",
                "the blender",
                "a cheap nonstick pan that's somehow still alive",
                "tongs",
                "pressure cooker",
                "a food scale",
                "a garlic press, fight me"
            ],
            followUps: ["i need a better knife honestly", "i have like four of the same spatula"],
            hostKeywords: ["tool", "knife", "pan", "kitchen", "gadget", "utensil"]
        ),
        ChatTopic(
            id: "ck.cookfor",
            scenes: ["Cooking & food"],
            openers: ["who do you usually cook for", "cooking for yourself or other people?", "anyone here cook for family every night"],
            answers: [
                "just me, so lots of leftovers",
                "family of five, it's a lot",
                "my partner, we take turns",
                "roommates sometimes",
                "i don't cook, i reheat",
                "my kids, they hate everything",
                "big dinners on sundays only",
                "friends on weekends",
                "just me and my dog watching",
                "my parents, i'm the cook now",
                "nobody, i order in",
                "i meal prep for the week"
            ],
            followUps: ["cooking for one is harder than it looks", "cooking for people is more fun i think"],
            hostKeywords: ["cook", "cooking", "family", "kids", "prep"]
        )
    ]

    // MARK: - IRL & outdoors

    private static let outdoors: [ChatTopic] = [
        ChatTopic(
            id: "ir.walks",
            scenes: ["IRL & outdoors"],
            openers: ["anyone else go on walks just to think", "favorite walking route?", "how far do you usually walk"],
            answers: [
                "around the block twice",
                "along the river by my place",
                "through the park at night",
                "to the store and back, that's it",
                "an hour every evening with the dog",
                "no route, i just turn randomly",
                "treadmill, it's too cold outside",
                "the long way to work",
                "up a big hill near my house",
                "i count steps, about 8k a day",
                "only when my car is in the shop",
                "laps around my office building"
            ],
            followUps: ["might go for a walk tomorrow", "walking at night is the best time"],
            hostKeywords: ["walk", "walking", "route", "steps", "park", "stroll"]
        ),
        ChatTopic(
            id: "ir.hotcold",
            scenes: ["IRL & outdoors"],
            openers: ["would you rather be too hot or too cold", "hot weather or cold weather people?", "heat or cold, which is worse"],
            answers: [
                "cold, you can always add layers",
                "hot, i hate being cold",
                "neither, i want 18 degrees forever",
                "cold, sweating is the worst",
                "hot, as long as there's water nearby",
                "cold but my hands freeze",
                "cold, heat makes me sleepy",
                "cold, i run hot anyway",
                "hot, i grew up somewhere warm",
                "dry heat yes, humid no",
                "cold, the air feels clean",
                "i complain either way"
            ],
            followUps: ["this is the one debate chat never agrees on", "i'm cold right now so"],
            hostKeywords: ["heat", "warm", "temperature", "freezing", "humid"]
        ),
        ChatTopic(
            id: "ir.powerbank",
            scenes: ["IRL & outdoors"],
            openers: ["do you carry a power bank", "how do you keep your phone alive outside all day", "power bank people?"],
            answers: [
                "power bank always in my bag",
                "never, and my phone always dies",
                "car charger",
                "low power mode from noon",
                "i carry a cable and beg in cafes",
                "two power banks, i'm prepared",
                "i just let it die, freedom",
                "my phone still lasts all day",
                "solar charger, very nerdy",
                "i turn off everything except maps",
                "i forget the charged one at home",
                "borrow from friends"
            ],
            followUps: ["my battery is not doing well right now", "a power bank has saved me so many times"],
            hostKeywords: ["powerbank", "power", "charger", "dying", "battery"]
        ),
        ChatTopic(
            id: "ir.peoplewatch",
            scenes: ["IRL & outdoors"],
            openers: ["anyone else love people watching", "people watching, yes or no", "best place to people watch?"],
            answers: [
                "airports, nothing beats it",
                "coffee shop window seat",
                "train stations",
                "the mall on a saturday",
                "i make up stories about everyone",
                "i feel weird doing it",
                "park benches",
                "outside a grocery store, very entertaining",
                "i do it from my balcony",
                "dog parks, the dogs mostly",
                "concerts",
                "only when i'm waiting for someone"
            ],
            followUps: ["i could do it for hours", "it's free entertainment honestly"],
            hostKeywords: ["people", "crowd", "busy", "strangers", "crowded"]
        ),
        ChatTopic(
            id: "ir.direction",
            scenes: ["IRL & outdoors"],
            openers: ["good sense of direction or nah", "do you get lost easily", "maps app or just walk?"],
            answers: [
                "i get lost in my own neighborhood",
                "great sense of direction, never use maps",
                "maps app for everything",
                "i walk the wrong way first every time",
                "i remember landmarks, not streets",
                "fine until i come out of a subway",
                "i ask strangers, old school",
                "i have to turn the map to face the way i'm going",
                "never lost, just exploring",
                "my friends don't let me lead",
                "decent in cities, hopeless in forests",
                "i follow the person in front of me"
            ],
            followUps: ["honestly i'm lost half the time", "maps saved me so many times"],
            hostKeywords: ["lost", "direction", "map", "maps", "navigate", "directions"]
        ),
        ChatTopic(
            id: "ir.shoes",
            scenes: ["IRL & outdoors"],
            openers: ["what shoes do you wear for walking around all day", "comfy shoes, what's everyone wearing", "sneakers or boots for outside"],
            answers: [
                "running shoes, every day",
                "old sneakers with holes in them",
                "boots, even in summer",
                "sandals as long as possible",
                "whatever's by the door",
                "hiking boots, they're broken in",
                "slip ons, laces are annoying",
                "the same pair for 4 years",
                "flats and i regret it after an hour",
                "barefoot shoes, weird but good",
                "work boots",
                "socks inside the house, does that count"
            ],
            followUps: ["my feet hurt just reading this", "i need new shoes honestly"],
            hostKeywords: ["shoes", "sneakers", "boots", "feet", "wear"]
        ),
        ChatTopic(
            id: "ir.headphones",
            scenes: ["IRL & outdoors"],
            openers: ["headphones on when you're out or nah", "do you listen to stuff while walking", "outside with headphones or no"],
            answers: [
                "always, can't leave without them",
                "never, i like hearing things",
                "one earbud in, safety first",
                "podcasts on every walk",
                "only on the bus",
                "no, i talk to my dog the whole time",
                "noise cancelling on, world off",
                "i forget them every single time",
                "music when running, nothing when walking",
                "phone calls with my sister usually",
                "only when it's crowded",
                "they're always dead when i need them"
            ],
            followUps: ["i'm wearing mine right now", "silence while walking sounds nice actually"],
            hostKeywords: ["headphones", "earbuds", "podcast", "podcasts", "earphones"]
        )
    ]

    // MARK: - Music & practice

    private static let music: [ChatTopic] = [
        ChatTopic(
            id: "mu.practice",
            scenes: ["Music & practice"],
            openers: ["how often do you all practice", "daily practice people?", "how long do you practice in a session"],
            answers: [
                "20 minutes a day, every day",
                "a few hours on weekends",
                "whenever i feel like it, so rarely",
                "an hour before bed",
                "i practice in my head on the bus",
                "every morning before work",
                "used to do 3 hours, now 30 minutes",
                "only before lessons, oops",
                "i noodle more than i practice",
                "10 minutes on busy days",
                "i don't practice, i just play songs i like",
                "two short sessions a day"
            ],
            followUps: ["noodling counts a little", "i need to be more consistent"],
            hostKeywords: ["practice", "practicing", "daily", "hours", "session"]
        ),
        ChatTopic(
            id: "mu.first",
            scenes: ["Music & practice"],
            openers: ["what was your first instrument", "anyone else start on recorder", "first instrument you ever played?"],
            answers: [
                "recorder in school like everyone",
                "piano lessons at 7",
                "guitar from a garage sale",
                "violin, hated it then, love it now",
                "drums, my parents regret it",
                "a toy keyboard",
                "trumpet in the school band",
                "ukulele, then gave up",
                "never played one",
                "clarinet",
                "my voice, choir kid",
                "bass because no one else wanted it",
                "harmonica"
            ],
            followUps: ["recorder trauma is universal", "i miss playing honestly"],
            hostKeywords: ["instrument", "instruments", "first", "lessons", "started"]
        ),
        ChatTopic(
            id: "mu.metronome",
            scenes: ["Music & practice"],
            openers: ["metronome, yes or no", "do you use a metronome when you practice", "anyone actually like the metronome"],
            answers: [
                "always, it keeps me honest",
                "i hate it but i need it",
                "never, i play by feel",
                "only for the hard parts",
                "drum tracks instead of clicks",
                "it makes me nervous somehow",
                "i tap my foot, that's my metronome",
                "phone app, set to 60 when i'm learning",
                "i turn it on and then ignore it",
                "started using it and got way better",
                "my teacher made me, now i'm used to it",
                "only for speeding up slowly"
            ],
            followUps: ["the metronome always wins in the end", "ok i'm turning mine on"],
            hostKeywords: ["metronome", "tempo", "timing", "click", "rhythm", "bpm"]
        ),
        ChatTopic(
            id: "mu.stagefright",
            scenes: ["Music & practice"],
            openers: ["anyone get nervous playing in front of people", "stage fright, who has it", "playing for others, scary or fun?"],
            answers: [
                "my hands shake every time",
                "fun once i start",
                "can't even play in front of my family",
                "fine on stage, terrified at small gatherings",
                "i forget everything i know",
                "i close my eyes and pretend no one's there",
                "never played for anyone",
                "the first minute is the worst",
                "i love it actually",
                "only nervous when someone records",
                "i mess up the easy parts, not the hard ones",
                "it got better after a few times"
            ],
            followUps: ["being nervous is normal i think", "i'd be terrified honestly"],
            hostKeywords: ["nervous", "stage", "perform", "audience", "scared", "fright"]
        ),
        ChatTopic(
            id: "mu.ear",
            scenes: ["Music & practice"],
            openers: ["do you read sheet music or play by ear", "sheet music people vs ear people", "can you read music?"],
            answers: [
                "read music, can't play by ear at all",
                "ear only, notes look like bugs to me",
                "tabs, does that count",
                "both but slowly",
                "learned to read in school, forgot it",
                "by ear, from videos",
                "chord charts are enough for me",
                "sight reading is my favorite part",
                "i read the first line and then guess",
                "learning to read now",
                "numbers written over the notes, i'm a beginner",
                "only what my teacher writes down for me"
            ],
            followUps: ["tabs definitely count", "i wish i could do both"],
            hostKeywords: ["sheet", "ear", "notes", "tabs", "chords", "sight"]
        ),
        ChatTopic(
            id: "mu.fingers",
            scenes: ["Music & practice"],
            openers: ["do your fingers hurt when you practice a lot", "sore hands after practicing, anyone?", "how do you deal with sore fingers"],
            answers: [
                "calluses took weeks to build",
                "my wrist hurts more than my fingers",
                "never had a problem",
                "i stretch before, it helps",
                "fingertips were numb for a month",
                "i ice them, not sure it does anything",
                "i stop when it hurts",
                "blisters from drums are the worst",
                "my back hurts more from sitting",
                "lighter strings fixed it for me",
                "it went away eventually",
                "my lips get tired, trumpet player"
            ],
            followUps: ["my hands are tired just reading this", "taking breaks helps me i think"],
            hostKeywords: ["fingers", "hands", "sore", "hurt", "pain", "calluses"]
        ),
        ChatTopic(
            id: "mu.neighbors",
            scenes: ["Music & practice"],
            openers: ["do your neighbors ever complain about the noise", "anyone else practice quietly so the neighbors don't hear", "practicing in an apartment, how do you manage"],
            answers: [
                "my neighbor knocks on the wall",
                "headphones on an electric one",
                "i only play during the day",
                "they've never said anything",
                "my downstairs neighbor plays too so we're even",
                "i use a practice mute",
                "garage practice only",
                "they complained once and i bought a rug",
                "i live in a house so nobody cares",
                "my roommate leaves when i practice",
                "i play at the park sometimes",
                "my mom is my neighbor and she complains"
            ],
            followUps: ["neighbors are the hardest part honestly", "i'd be scared to play loud"],
            hostKeywords: ["neighbors", "neighbor", "noise", "loud", "apartment", "quiet"]
        )
    ]

    // MARK: - Focus & study

    private static let study: [ChatTopic] = [
        ChatTopic(
            id: "st.focus",
            scenes: ["Focus & study"],
            openers: ["how do you all focus when studying", "focus methods, what works for you", "anyone have a trick for actually concentrating"],
            answers: [
                "pomodoro, 25 and 5",
                "phone in another room",
                "library, can't slack there",
                "i need background noise",
                "a to do list with tiny steps",
                "deadline panic is my method",
                "website blocker on my laptop",
                "study with friends on call",
                "i work best right after the gym",
                "i don't, i just hope",
                "cleaning my desk first",
                "writing down every distraction then ignoring it"
            ],
            followUps: ["i'm going to try a few of these", "focusing is so hard lately"],
            hostKeywords: ["focus", "concentrate", "concentrating", "distracted", "pomodoro"]
        ),
        ChatTopic(
            id: "st.coffee",
            scenes: ["Focus & study"],
            openers: ["how much coffee does studying take", "study fuel, coffee or tea?", "what keeps you awake when studying"],
            answers: [
                "two coffees minimum",
                "tea, coffee makes me shaky",
                "energy drinks, i know",
                "nothing, i go to sleep",
                "cold water and a cold room",
                "matcha",
                "coffee after 3pm ruins my sleep so no",
                "chewing gum somehow works",
                "a snack every hour",
                "standing up when i get sleepy",
                "decaf, placebo effect",
                "one big coffee and pray"
            ],
            followUps: ["i'm on my second cup already", "caffeine is the real study partner"],
            hostKeywords: ["coffee", "caffeine", "awake", "energy", "sleepy"]
        ),
        ChatTopic(
            id: "st.deadlines",
            scenes: ["Focus & study"],
            openers: ["anyone have a deadline coming up", "deadline check, how close are we", "who's cramming for something right now"],
            answers: [
                "tomorrow at 9am, don't ask",
                "essay due friday, haven't started",
                "exam next week",
                "done early for once",
                "three things due the same day",
                "no deadlines, just here",
                "work report due in an hour",
                "finished one at 3am last night",
                "group project, nobody's done anything",
                "already submitted, now i'm free",
                "midterms all week",
                "i asked for an extension"
            ],
            followUps: ["good luck to everyone with stuff due", "i should be working on mine"],
            hostKeywords: ["deadline", "due", "exam", "essay", "test", "homework", "assignment"]
        ),
        ChatTopic(
            id: "st.breaks",
            scenes: ["Focus & study"],
            openers: ["what do you do on study breaks", "break activities, what's yours", "how long are your breaks really"],
            answers: [
                "5 minute break turns into an hour",
                "walk around the house",
                "snack run",
                "stretch on the floor",
                "scroll my phone, bad idea",
                "make tea",
                "short nap, 20 minutes max",
                "play one song on guitar",
                "pet my cat",
                "a quick game, never quick",
                "go outside for air",
                "do some dishes, weirdly relaxing"
            ],
            followUps: ["i need a break right now honestly", "breaks are harder than studying"],
            hostKeywords: ["break", "breaks", "pause", "relax", "recharge"]
        ),
        ChatTopic(
            id: "st.notes",
            scenes: ["Focus & study"],
            openers: ["paper notes or digital", "how do you take notes", "notebook or laptop for notes?"],
            answers: [
                "paper, i remember it better",
                "laptop, i type faster",
                "tablet with a pen",
                "i don't take notes, just listen",
                "colored pens, very aesthetic",
                "flashcards for everything",
                "i record lectures and never listen",
                "messy notebook only i can read",
                "digital but i print them",
                "sticky notes all over my desk",
                "i rewrite my notes neatly after",
                "photos of the board"
            ],
            followUps: ["i should go back to paper honestly", "my notes are a disaster right now"],
            hostKeywords: ["notes", "notebook", "paper", "digital", "flashcards"]
        ),
        ChatTopic(
            id: "st.lyrics",
            scenes: ["Focus & study"],
            openers: ["can you study with lyrics on", "music with words while studying, yes or no", "what do you listen to while you study"],
            answers: [
                "no lyrics or i start singing",
                "lyrics are fine if i know the song",
                "instrumental, but lyrics are fine for math",
                "silence, total silence",
                "music in another language works",
                "same album on repeat",
                "piano covers of pop songs",
                "i put on a long mix and forget it",
                "loud music helps me, weird i know",
                "cafe noise",
                "anything but podcasts",
                "movie soundtracks"
            ],
            followUps: ["i can't do lyrics at all", "i'm on silence tonight"],
            hostKeywords: ["lyrics", "instrumental", "album", "mix", "study"]
        ),
        ChatTopic(
            id: "st.procrastinate",
            scenes: ["Focus & study"],
            openers: ["what's your favorite way to procrastinate", "procrastination check, what are you avoiding", "how do you procrastinate"],
            answers: [
                "cleaning my whole room suddenly",
                "watching streams, obviously",
                "reorganizing my notes instead of reading them",
                "making a study plan and not following it",
                "snacks every ten minutes",
                "researching something completely random",
                "replying to every message i ignored all week",
                "doing other homework",
                "i don't, i panic instead",
                "taking 'quick' naps",
                "rearranging my desk",
                "watching videos about productivity"
            ],
            followUps: ["well i'm literally doing it right now", "we're all avoiding something huh"],
            hostKeywords: ["procrastinate", "procrastinating", "procrastination", "avoid", "avoiding", "lazy"]
        )
    ]

    // MARK: - Short reactions (repeatable)

    static let short: [String: [String]] = [
        "laugh": ["lol", "LMAO", "haha", "😭", "💀", "dead", "im crying", "lmaooo", "pfft", "lol what", "that got me", "crying", "ha!", "LOL ok", "help 😭", "i'm wheezing", "rofl"],
        "agree": ["real", "fr", "facts", "same", "this", "yep", "exactly", "agreed", "so true", "100%", "honestly yeah", "yeah", "mood", "literally me", "big agree", "correct", "fair point"],
        "disagree": ["nah", "hmm no", "disagree", "no chance", "eh", "not really", "debatable", "nope", "i doubt it", "hard disagree", "not sure about that", "ehh idk", "wrong lol", "respectfully no", "that's a stretch", "absolutely not"],
        "hype": ["LETS GOOO", "W", "huge", "sheesh", "insane", "hype", "yesss", "massive", "ayy", "here we go", "oh yeah", "🔥", "big moment", "yooo", "absolute W"],
        "sympathy": ["unlucky", "ouch", "pain", "sad", "that sucks", "aw man", "brutal", "rough", "o7", "it happens", "😔", "damn", "oh no", "yikes", "tough", "big oof"],
        "surprise": ["wait what", "uh what", "WHAT", "?!", "omg", "whoa", "wait", "hold on", "excuse me?", "how", "bro what", "wait really", "😳", "oh", "no way"],
        "neutral": ["ok", "hm", "interesting", "i see", "noted", "sure", "makes sense", "alright", "cool", "oh ok", "kk", "got it", "neat", "huh ok", "mhm"],
        "greeting": ["hi", "hello", "hey", "yo", "hiii", "o/", "sup", "evening", "hi chat", "heyo", "morning", "hey all", "howdy", "hii everyone", "wassup", "hello hello"],
        "question": ["huh?", "wdym", "why", "what happened", "wait why", "how so", "explain?", "what did i miss", "context?", "is that good?", "who?", "where?", "for real?", "what was that", "same question", "what do you mean"]
    ]

    // MARK: - Event reactions

    static let events: [String: [String]] = [
        "Laugh": [
            "ok what was so funny",
            "that laugh is contagious honestly",
            "i missed it, what happened",
            "lmao i need a replay of that",
            "i laughed out loud in a quiet room",
            "my roommate thinks i'm weird now",
            "ok that was actually funny",
            "i'm laughing and i don't even know why",
            "someone explain the joke to me",
            "i heard that from the kitchen",
            "wait rewind, i was getting water",
            "that's going to stay in my head all day",
            "i wasn't ready for that",
            "why is that so funny to me",
            "ok i needed that laugh today",
            "good thing i wasn't drinking anything",
            "can't breathe, give me a second",
            "chat is losing it right now"
        ],
        "Laugh.quick": ["LMAO STOP", "HAHAHA", "i'm dead", "😂", "omg lol", "screaming", "bahaha", "too good", "lmaoo ok", "stoppp", "LOLLL", "hahaha what"],
        "Win": [
            "wait did that actually work",
            "you earned that one",
            "called it, knew you had it",
            "i jumped off my couch",
            "was that first try?",
            "ok that was impressive",
            "my heart rate went up for that",
            "chat we witnessed something",
            "i clapped alone in my room",
            "never doubted you, mostly",
            "screaming quietly because everyone's asleep",
            "how did you pull that off",
            "i'm still processing that",
            "someone clip that please",
            "about time, nice job",
            "all that effort paid off",
            "i had a feeling it would go well",
            "did not expect that, nice"
        ],
        "Win.quick": ["GG", "lets go", "clean", "EZ", "huge W", "nailed it", "WOOO", "finally", "gg wp", "so clean", "ayyy", "YOU DID IT"],
        "Fail": [
            "oh no, so close",
            "that hurt to watch",
            "ouch, you had it",
            "it's fine, nobody saw that",
            "i felt that in my soul",
            "deep breath, next one",
            "well, that sure happened",
            "that one's not on you",
            "rip, we go again",
            "ok that one was rough",
            "i'd have given up already",
            "the universe said no today",
            "we'll pretend that didn't happen",
            "i covered my eyes for that",
            "that's going in the blooper reel",
            "my condolences, truly lol",
            "you were right there too",
            "that was cursed honestly"
        ],
        "Fail.quick": ["oof", "rip", "F", "nooo", "so close", "next time", "almost", "ouchie", "noo why", "rip lol", "classic", "it's ok"],
        "Debate": [
            "ok i have opinions about this",
            "chat is split on this one",
            "i'm staying out of this one",
            "both sides have a point honestly",
            "this is how friendships end",
            "i'm on your side, probably",
            "hot take incoming, brace yourselves",
            "hmm i actually disagree",
            "can we vote on this",
            "wait what's the argument again",
            "i'll take the unpopular side",
            "grabbing popcorn for this",
            "my answer would start a fight",
            "this debate never ends",
            "depends how you look at it",
            "the correct answer is obvious to me",
            "whoever types the most wins, right?",
            "i changed my mind twice already"
        ],
        "Debate.quick": ["hot take", "spicy", "objection", "valid point", "counterpoint", "both wrong", "ehhh", "team you", "true tho", "nope, wrong", "points were made", "popcorn time"],
        "BRB": [
            "take your time, we're fine",
            "snack break? grab me one",
            "bring back some water for us",
            "chat, behave while they're gone",
            "i'll be right here waiting",
            "perfect time for me to refill my drink",
            "stretch break for everyone then",
            "we'll talk about you while you're gone",
            "the chat is unsupervised now",
            "time to stand up i guess",
            "going to grab food too",
            "don't forget to come back",
            "hurry back, we'll wait",
            "who else is just staring at the empty room",
            "good time for a bathroom break",
            "ok chat, nobody touch anything"
        ],
        "BRB.quick": ["take your time", "ok see ya", "we wait", "no rush", "brb too", "go go", "we'll be here", "👋", "stretch time", "snack break"],
        "Back": [
            "welcome back, we missed you",
            "that was quick, nice",
            "back already? that was fast",
            "chat was very well behaved, promise",
            "you didn't miss anything, don't worry",
            "did you bring snacks",
            "wb, what did you grab",
            "ok we're back in business",
            "perfect timing, i just got back too",
            "we talked about you, all good things",
            "everyone sit back down",
            "ok where were we",
            "did you get water at least",
            "chat almost fell asleep without you",
            "good, i was getting bored"
        ],
        "Back.quick": ["wb", "welcome back", "yay", "hey again", "there they are", "about time", "they're back", "wooo hi", "re hi", "oh good"],
        "Smile detected": [
            "ok that smile though",
            "what's got you smiling",
            "ok who said something funny",
            "something going right today?",
            "smiling at chat or at your phone?",
            "i saw that smile, don't hide it",
            "secret smile, what are we missing",
            "good news or something?",
            "smiling makes me smile too",
            "did someone text you something nice?",
            "caught you grinning there",
            "ok now i'm curious, why the smile"
        ],
        "Smile detected.quick": ["😊", ":)", "smiley", "awww", "that grin", "😄", ":D", "happy vibes", "hehe", "big smile"],
        "Face out of frame": [
            "hey, where'd you go?",
            "did you leave us?",
            "hello? is anyone there?",
            "we lost you for a sec",
            "just us and the background now",
            "are you still there?",
            "chat, they just vanished",
            "talking to an empty frame here",
            "turned away from the camera?",
            "is the camera pointed somewhere else?",
            "just the room now lol",
            "did something happen off camera?",
            "are you hiding from chat?",
            "camera shy all of a sudden?",
            "hope everything's ok over there",
            "guess we wait then"
        ],
        "Face out of frame.quick": ["u there?", "??", "where'd they go", "gone", "uh oh", "helloooo", "ghost mode", "lost them", "anyone?", "👀"],
        "Face in frame": [
            "oh hey, you're back in view",
            "there you are, found you",
            "ok we can see you again",
            "welcome back to the frame",
            "and they're back on camera",
            "hi again, missed your face",
            "there's the face we know",
            "back in the shot, nice",
            "ah, you came back to us",
            "camera found you again",
            "oh hi, didn't see you come back",
            "good, we're not alone anymore",
            "phew, thought you left",
            "you were gone for a bit there"
        ],
        "Face in frame.quick": ["there you are", "found you", "hii", "oh hey", "peekaboo", "hello again", "welcome", "spotted", "ayy hi", "hi face"],
        "Camera movement": [
            "whoa, where are we going",
            "camera is moving, what's happening",
            "little earthquake there lol",
            "did the camera fall?",
            "are you moving the phone?",
            "the view just changed, where are we",
            "getting a little dizzy lol",
            "are we going on a tour?",
            "steady camera please, my stomach",
            "did you bump it?",
            "new angle, i like it",
            "ok what are you showing us",
            "are you walking somewhere?",
            "careful with the camera there",
            "is something going on over there?",
            "whoa that was a lot of movement"
        ],
        "Camera movement.quick": ["wheee", "dizzy", "zoom", "earthquake", "😵", "where to?", "shaky cam", "steady!", "tour time", "woah"],
        "Pet in view": [
            "wait, is that a pet back there?",
            "is that a cat or a dog? can't tell",
            "wait, do i spot a floof?",
            "who is that little creature",
            "pet tax has been paid",
            "that's a cute floof, whatever it is",
            "the pet wants attention",
            "give the floof a scratch from me",
            "the real star just showed up",
            "chat, we have a visitor",
            "is the floof friendly?",
            "what's the pet's name?",
            "more of the floof please",
            "my dog would love to meet them",
            "four legs spotted, need confirmation",
            "how old is the pet?",
            "does the pet always join the stream?"
        ],
        "Pet in view.quick": ["FLOOF", "pet!!", "cutie", "omg pet", "floof alert", "hi pet", "🐾", "pet tax", "baby!!", "smol"],
        "Food in view": [
            "wait what are you eating",
            "is that food i see?",
            "what's on the plate",
            "that looks good, what is it",
            "is it snack time already?",
            "i'm hungry now, thanks",
            "share with chat please",
            "did you cook that yourself?",
            "what kind of food is that",
            "now i want snacks too",
            "is that dinner or a snack?",
            "i can't tell what it is but i want it",
            "eating on camera, bold move",
            "what are we having tonight",
            "is that homemade or takeout?",
            "how does it taste?"
        ],
        "Food in view.quick": ["yum", "food!", "hungry now", "mmm", "share", "nom", "jealous", "😋", "what is it", "snack?"],
        "Outdoor view": [
            "wait, are you outside?",
            "ooh, fresh air stream",
            "outside? where are we",
            "is it cold out there?",
            "going on an adventure?",
            "outdoor stream, nice change",
            "what's the weather doing there?",
            "touching grass today i see",
            "be careful out there",
            "where are you headed?",
            "is it windy there?",
            "now i want to go outside too",
            "irl time? where to",
            "is it nice out over there?",
            "how far are you going?",
            "anyone else around out there?"
        ],
        "Outdoor view.quick": ["outside!", "fresh air", "irl!", "ooh outside", "adventure", "nature", "grass!", "touch grass", "🌳", "outdoors?"],
        "Instrument in view": [
            "wait, is that an instrument?",
            "are you going to play something?",
            "what instrument is that exactly?",
            "have you had it long?",
            "is it concert time now?",
            "i used to play something like that",
            "do you take requests or nah",
            "is that yours or borrowed?",
            "can't hear anything yet but i'm ready",
            "music break? i'm in",
            "i wish i could play anything at all",
            "wait i didn't know you played",
            "is that a guitar or something else?",
            "is practice happening tonight?",
            "ooh, are you practicing something?"
        ],
        "Instrument in view.quick": ["music!", "play!", "ooh music", "🎵", "concert?", "jam time", "play something", "🎶", "yes music", "song?"]
    ]

    // MARK: - Replies to the host

    static let hostReplies: [String: [String]] = [
        "yes": ["yes do it", "honestly yes", "yep yep", "100% yes", "i'd say yes", "yes obviously", "sure, why not", "go for it", "yeah i think so", "absolutely", "yes yes yes", "def yes", "i vote yes", "easy yes", "yeah no doubt"],
        "no": ["no", "nope, don't", "i'd say no", "probably not", "hard no", "no way lol", "not a chance", "nah, skip it", "please no", "honestly no", "i vote no", "no thanks", "eh, no", "definitely not", "no lol"],
        "unsure": ["depends", "maybe?", "not sure tbh", "could go either way", "hmm hard to say", "50/50", "ask me later", "idk honestly", "maybe, maybe not", "kinda?", "no clue", "kinda depends on my mood", "i'm torn", "sort of?", "let me think"],
        "open": ["hmm good question", "no idea honestly", "what do you think?", "pass", "ask me again after coffee", "oh that's a tough one", "uhh", "give me a minute on that one", "never thought about it", "you first", "i'll get back to you", "chat?", "my brain is off, sorry", "that's a whole conversation", "i have thoughts but they're messy", "good one, i need to think"],
        "greeting": ["hey, how's your day", "hi there :)", "yo what's up", "hiya", "hey hey hey", "hi again", "good evening!", "good to see you", "hey there", "hi from work", "hey, just got here", "hellooo", "heyy", "hi hi"],
        "howAreYou": ["tired but good", "pretty good, you?", "can't complain", "doing alright", "long day but ok", "good actually!", "meh, it's fine", "sleepy", "better now", "hungry lol", "not bad, how about you?", "surviving", "great, day off today", "ok i guess", "stressed but fine"],
        "thanks": ["no thank you", "aw ok", "thank you too", "glad to hang out", "for sure", "no need to thank us", "hey no problem", "we're happy to be here", "it's mutual", "you're welcome!", "of course", "aww", "thanks for having us", "yeah of course", "cheers"],
        "bye": ["night!", "this was fun", "bye!", "see you next time", "night night", "take care", "byeee", "good stream", "see ya", "until next time", "sleep well", "later!", "already? ok bye", "catch you tomorrow maybe", "o7 night"],
        "statement": ["fair", "valid", "that's fair honestly", "true", "makes sense to me", "can't argue with that", "i get that", "hm ok", "same here", "fair enough", "agree honestly", "yeah that tracks", "interesting take", "i kinda agree", "ok noted", "huh, fair", "respect"],
        "choice": ["both", "neither", "both obviously", "depends on the day", "why not both", "the first one probably", "the second one", "can't pick", "whichever is easier", "both are good honestly", "flip a coin", "ask me tomorrow", "whatever you feel like", "chat will fight about this", "hmm tough call", "no wrong answer"],
        "nonEnglish": ["wait what does that mean", "translate pls?", "no idea what that says but ok", "i don't speak that, sorry", "english pls? lol", "that went over my head", "can someone translate", "i caught zero words of that", "ok i'll pretend i understood", "cool, i think?", "what language is that?", "i'll just nod along", "my translator gave up", "looks nice whatever it means"]
    ]

    // MARK: - Viewers talking to the host

    static let viewerToHost: [String: [String]] = [
        "any": [
            "how long are you streaming today?",
            "what's the plan for tonight?",
            "first time catching you live",
            "do you stream every day?",
            "how was your day?",
            "what time do you usually go live?",
            "how long have you been streaming?",
            "did you eat yet?",
            "what are you drinking?",
            "do you read chat after?",
            "found you randomly, hello",
            "are you streaming tomorrow too?",
            "what's the best thing that happened today?",
            "how's your week going?",
            "been watching a while, first time typing",
            "any plans after stream?",
            "what got you into streaming?",
            "do you have pets?"
        ],
        "Just chatting": [
            "what should we talk about?",
            "got any stories from this week?",
            "what are you looking forward to?",
            "favorite topic to ramble about?",
            "any hot takes today?",
            "what's the last thing that made you laugh?",
            "seen anything good lately?",
            "what's on your mind tonight?"
        ],
        "Late night gaming": [
            "what are you playing next?",
            "do you play with friends or solo?",
            "pad or mouse for you?",
            "how late are you going tonight?",
            "what's your favorite game ever?",
            "do you replay stuff or only new games?",
            "what difficulty do you usually pick?",
            "do you have a gaming setup you like?"
        ],
        "One more attempt": [
            "how many attempts so far?",
            "what's the goal tonight?",
            "how long have you been at this?",
            "are you stopping after the next one?",
            "do you have a set number of tries tonight?",
            "what's the hardest part so far?",
            "best attempt so far?",
            "you taking a break soon?"
        ],
        "Cooking & food": [
            "what are we cooking today?",
            "do you cook every day?",
            "favorite thing to make?",
            "is this a family recipe?",
            "how spicy do you like things?",
            "who taught you to cook?",
            "what's for dessert?",
            "do you do the dishes right after?"
        ],
        "IRL & outdoors": [
            "where are you going today?",
            "how long are you out for?",
            "is it busy where you are?",
            "how's your battery holding up?",
            "do you walk this way often?",
            "any stops planned today?",
            "how is it out there today?",
            "are you walking or driving?"
        ],
        "Music & practice": [
            "how many years have you played?",
            "do you take lessons?",
            "what are you working on lately?",
            "do you write your own stuff?",
            "how many hours do you practice?",
            "what got you into music?",
            "do you play any other instruments?",
            "what's the hardest thing you've learned?"
        ],
        "Focus & study": [
            "what are you studying?",
            "how long is the focus session?",
            "pomodoro or long blocks?",
            "when's your next break?",
            "what subject is it?",
            "is it for a class or for fun?",
            "how much do you have left to do?",
            "do you study better at night or in the day?"
        ]
    ]

    // MARK: - Presence

    static let presence: [String: [String]] = [
        "join": ["hi all", "just got here, what did i miss", "evening chat", "hey everyone", "made it", "hello, just joined", "sup chat", "finally home, hi", "late as usual, hi", "hi from the bus", "what's going on in here", "just woke up, hi", "hey hey", "hi, first time here", "back from work, hi all"],
        "leave": ["gotta head out, night all", "dinner time, bye", "ok i'm off, later", "bed time for me", "gotta go to work, bye", "battery dying, bye chat", "heading out, have a good one", "bye all", "leaving for a bit, might be back", "class starting, gotta go", "time to sleep, night", "work call, bye", "my bus stop, later", "ok that's me for tonight"],
        "back": ["back", "back, did i miss much", "ok i'm back", "and i'm back", "back from dinner", "returned", "sorry, got pulled away, back now", "back with snacks", "back, what happened", "made it back", "phone died, back now", "back from walking the dog", "back after my meeting"],
        "lurk": ["just lurking tonight", "lurking from work", "quiet lurk today", "lurking while i cook", "on in the background", "lurk mode", "lurking from bed", "lurking but i'm here", "half watching, half working", "lurking while i study", "lurking on my break", "in the background while i clean"]
    ]

    // MARK: - Tip notes

    static let tipNotes: [String: [String]] = [
        "any": ["for the coffee fund", "small one, have a good night", "first time tipping, hi", "keep it up", "just because", "thanks for the company", "for snacks", "been lurking for weeks, here", "here you go", "treat yourself to something", "for the late night", "happy friday or whatever day it is", "don't spend it all at once", "no reason", "a little something", "quiet lurker, quick tip"],
        "Win": ["for that win", "earned it", "gg, take this", "knew you'd get it", "victory tip", "that was worth it"],
        "Fail": ["for the next try", "you'll get it", "unlucky, here's something", "consolation prize", "shake it off", "that one hurt, here"],
        "big": ["saved up for this one", "because why not", "go do something nice with it", "for the whole week of streams", "had a good month, sharing", "don't make a big deal of it lol", "for all the hours", "for upgrades or whatever"],
        "return": ["me again", "back with another", "still here, still tipping", "regular reporting in", "again, no reason"],
        "Just chatting": ["for the good conversation", "fun chat tonight", "for the stories", "thanks for answering my question", "for the chats"],
        "Late night gaming": ["for the next game", "energy drink money", "controller fund", "for late night snacks", "go to bed after this one lol"],
        "One more attempt": ["for attempt number whatever", "one more on me", "for your patience", "for the grind", "keep trying"],
        "Cooking & food": ["for groceries", "spice fund", "for the next recipe", "save me a plate", "for kitchen stuff"],
        "IRL & outdoors": ["for the walk", "bus fare", "get a drink while you're out", "for the battery pack", "enjoy the fresh air"],
        "Music & practice": ["for new strings", "for the music", "lesson money", "keep practicing", "for the practice time"],
        "Focus & study": ["for coffee while you study", "good luck on your exam", "study fuel", "for the focus", "take a break with this"]
    ]

    // MARK: - Chat reacting to someone else's tip

    static let giftReactions: [String: [String]] = [
        "small": ["nice one", "generous", "W tipper", "aw", "kind", "that's nice", "oh nice", "respect to that", "classy", "good stuff", "look at that", "very nice", "love that", "o7 tipper", "cheers to that", "nice gesture"],
        "large": ["big W", "damn ok", "WOW", "holy", "huge tip", "hold up, WHAT", "someone's rich lol", "generous much", "jaw on the floor", "ok big spender", "that's a lot", "ok wow", "chat went quiet lol", "what a legend", "massive W", "that's insane", "dang", "rich chat tonight"]
    ]

    // MARK: - Donor replies after being thanked

    static let thanksReplies: [String] = ["np!", "anytime", "you deserve it", "ofc", "glad to", "no worries", "happy to", "yw :)", "it's nothing", "enjoy it", "don't mention it", "all good", "thanks for streaming", "sure thing", "my pleasure", "least i could do", "hehe np", "keep going", "ok now i'm blushing", "no big deal", "always"]
}
