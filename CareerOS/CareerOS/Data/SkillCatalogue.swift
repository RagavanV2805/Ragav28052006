import Foundation

/// The global skill graph shared by every role. Prerequisite slugs must refer
/// to other entries here; `SeedService` validates the graph at seeding time.
enum SkillCatalogue {
    static let all: [SkillSeed] = fundamentals + languages + web + mobile + data + cloud + security + qa

    // MARK: - Fundamentals, CS & DSA

    static let fundamentals: [SkillSeed] = [
        .s("programming-fundamentals", "Programming Fundamentals",
           "Variables, control flow, functions and the mental model of how programs execute.",
           .fundamentals, 40,
           res: [
               .r(.course, "CS50x: Introduction to Computer Science", "Harvard", "https://cs50.harvard.edu/x/"),
               .r(.documentation, "The Python Tutorial", "python.org", "https://docs.python.org/3/tutorial/"),
               .r(.practice, "Exercism Tracks", "Exercism", "https://exercism.org/"),
           ]),
        .s("oop", "Object-Oriented Programming",
           "Classes, objects, inheritance, polymorphism and encapsulation — how to model real systems.",
           .fundamentals, 30, prereqs: ["programming-fundamentals"],
           res: [
               .r(.article, "OOP Concepts in Java", "Oracle", "https://docs.oracle.com/javase/tutorial/java/concepts/"),
               .r(.video, "Object-Oriented Programming Crash Course", "freeCodeCamp", "https://www.youtube.com/watch?v=pTB0EiLXUC8"),
           ]),
        .s("data-structures", "Data Structures",
           "Arrays, linked lists, stacks, queues, hash tables, trees and graphs — and when to use each.",
           .dataStructuresAlgorithms, 50, prereqs: ["programming-fundamentals"],
           res: [
               .r(.course, "Data Structures (UC San Diego)", "Coursera", "https://www.coursera.org/learn/data-structures", free: false),
               .r(.practice, "LeetCode Explore: Arrays & Strings", "LeetCode", "https://leetcode.com/explore/"),
               .r(.article, "VisuAlgo — Visualising Data Structures", "Steven Halim", "https://visualgo.net/en"),
           ]),
        .s("complexity-analysis", "Complexity Analysis",
           "Big-O reasoning about time and space so you can compare algorithm designs.",
           .dataStructuresAlgorithms, 12, prereqs: ["programming-fundamentals"],
           res: [
               .r(.article, "Big-O Cheat Sheet", "Big-O Cheat Sheet", "https://www.bigocheatsheet.com/"),
               .r(.video, "Big-O Notation in 100 Seconds", "Fireship", "https://www.youtube.com/watch?v=Mo4vesaut8g"),
           ]),
        .s("algorithms", "Algorithms",
           "Sorting, searching, recursion, two pointers, sliding windows and graph traversals.",
           .dataStructuresAlgorithms, 60, prereqs: ["data-structures", "complexity-analysis"],
           res: [
               .r(.practice, "NeetCode Roadmap", "NeetCode", "https://neetcode.io/roadmap"),
               .r(.practice, "LeetCode", "LeetCode", "https://leetcode.com/"),
               .r(.course, "Algorithms (Princeton)", "Coursera", "https://www.coursera.org/learn/algorithms-part1", free: false),
           ]),
        .s("advanced-algorithms", "Advanced Algorithms",
           "Dynamic programming, greedy strategies, backtracking and graph optimisation.",
           .dataStructuresAlgorithms, 50, prereqs: ["algorithms"],
           res: [
               .r(.practice, "NeetCode: Dynamic Programming", "NeetCode", "https://neetcode.io/roadmap"),
               .r(.video, "Dynamic Programming Lecture", "Abdul Bari", "https://www.youtube.com/watch?v=oBt53YbR9Kk"),
           ]),
        .s("problem-solving-practice", "Problem-Solving Practice",
           "A consistent competitive-programming style practice habit on curated problem sets.",
           .dataStructuresAlgorithms, 40, prereqs: ["data-structures"],
           res: [
               .r(.practice, "Codeforces", "Codeforces", "https://codeforces.com/"),
               .r(.practice, "HackerRank", "HackerRank", "https://www.hackerrank.com/"),
           ]),
        .s("dbms", "Database Fundamentals",
           "Relational modelling, normalisation, keys, indexes and transactions.",
           .dataAndDatabases, 25, prereqs: ["programming-fundamentals"],
           res: [
               .r(.course, "Databases (Stanford)", "edX / Stanford", "https://www.edx.org/learn/databases"),
               .r(.article, "Use The Index, Luke!", "Markus Winand", "https://use-the-index-luke.com/"),
           ]),
        .s("sql", "SQL",
           "Joins, aggregations, subqueries, window functions and query tuning.",
           .dataAndDatabases, 25, prereqs: ["dbms"],
           res: [
               .r(.practice, "SQLBolt Interactive Lessons", "SQLBolt", "https://sqlbolt.com/"),
               .r(.practice, "Select Star SQL", "Select Star SQL", "https://selectstarsql.com/"),
           ]),
        .s("operating-systems", "Operating Systems",
           "Processes, threads, memory, scheduling and file systems — the layer under your code.",
           .computerScience, 35, prereqs: ["programming-fundamentals"],
           res: [
               .r(.book, "Operating Systems: Three Easy Pieces", "Arpaci-Dusseau", "https://pages.cs.wisc.edu/~remzi/OSTEP/"),
           ]),
        .s("computer-networks", "Computer Networks",
           "The internet model: DNS, TCP/UDP, HTTP, TLS and how requests actually travel.",
           .computerScience, 30,
           res: [
               .r(.video, "Computer Networking Full Course", "freeCodeCamp", "https://www.youtube.com/watch?v=IPvYjXCsTg8"),
               .r(.article, "How DNS Works", "DNS Dashboard", "https://howdns.works/"),
           ]),
        .s("git-version-control", "Git & Version Control",
           "Commits, branches, merges, rebases and collaborative pull-request workflows.",
           .tools, 10,
           res: [
               .r(.book, "Pro Git", "Git", "https://git-scm.com/book/en/v2"),
               .r(.practice, "Learn Git Branching", "Peter Cottle", "https://learngitbranching.js.org/"),
           ]),
        .s("linux-basics", "Linux Basics",
           "Navigating the shell, file permissions, processes and environment configuration.",
           .tools, 15,
           res: [
               .r(.course, "The Missing Semester", "MIT", "https://missing.csail.mit.edu/"),
               .r(.practice, "Linux Journey", "Linux Journey", "https://linuxjourney.com/"),
           ]),
        .s("http-and-apis", "HTTP & APIs",
           "Requests, responses, status codes, headers and the anatomy of a web API.",
           .web, 12, prereqs: ["computer-networks"],
           res: [
               .r(.documentation, "HTTP Reference", "MDN", "https://developer.mozilla.org/en-US/docs/Web/HTTP"),
               .r(.article, "HTTP Status Codes", "http.dev", "https://http.dev/"),
           ]),
        .s("rest-api-design", "REST API Design",
           "Resource modelling, naming, pagination, versioning and error contracts.",
           .web, 15, prereqs: ["http-and-apis"],
           res: [
               .r(.article, "REST API Design Best Practices", "Postman", "https://blog.postman.com/rest-api-design-best-practices/"),
               .r(.practice, "Postman Learning Center", "Postman", "https://learning.postman.com/"),
           ]),
        .s("software-testing-fundamentals", "Testing Fundamentals",
           "Unit vs integration vs end-to-end tests, assertions, test doubles and coverage.",
           .testing, 15, prereqs: ["programming-fundamentals"],
           res: [
               .r(.article, "The Practical Test Pyramid", "Martin Fowler", "https://martinfowler.com/articles/practical-test-pyramid.html"),
           ]),
        .s("design-patterns", "Design Patterns",
           "Reusable solutions — factories, observers, strategies, decorators — and their trade-offs.",
           .architecture, 25, prereqs: ["oop"],
           res: [
               .r(.article, "Design Patterns Catalogue", "Refactoring Guru", "https://refactoring.guru/design-patterns"),
           ]),
        .s("system-design-basics", "System Design Basics",
           "Scalability, load balancing, caching, replication and how to reason about large systems.",
           .architecture, 30, prereqs: ["oop", "computer-networks", "dbms"],
           res: [
               .r(.article, "The System Design Primer", "GitHub", "https://github.com/donnemartin/system-design-primer"),
               .r(.article, "System Design Roadmap", "roadmap.sh", "https://roadmap.sh/system-design"),
           ]),
        .s("advanced-system-design", "Advanced System Design",
           "Sharding, event-driven architectures, consistency models and failure planning.",
           .architecture, 35, prereqs: ["system-design-basics"],
           res: [
               .r(.book, "Designing Data-Intensive Applications", "Martin Kleppmann", "https://dataintensive.net/", free: false),
           ]),
        .s("interview-preparation", "Interview Preparation",
           "Mock interviews, behavioural stories, problem walkthroughs and communication.",
           .career, 30, prereqs: ["data-structures", "algorithms"],
           res: [
               .r(.practice, "Pramp Mock Interviews", "Pramp", "https://www.pramp.com/"),
               .r(.article, "Tech Interview Handbook", "Yangshun Tay", "https://www.techinterviewhandbook.org/"),
           ]),
        .s("portfolio-projects", "Portfolio Projects",
           "Ship the projects recommended for your role and document them publicly.",
           .career, 40, prereqs: ["programming-fundamentals"],
           res: [
               .r(.article, "How to Build a Developer Portfolio", "roadmap.sh", "https://roadmap.sh/projects"),
           ]),
        .s("agile-delivery", "Agile Delivery",
           "Sprints, standups, tickets and how modern teams plan and review work.",
           .career, 8,
           res: [
               .r(.article, "The Scrum Guide", "Scrum.org", "https://scrumguides.org/scrum-guide.html"),
           ]),
    ]

    // MARK: - Programming Languages

    static let languages: [SkillSeed] = [
        .s("python", "Python",
           "Syntax, data types, comprehensions, modules and idiomatic Python.",
           .language, 40,
           res: [
               .r(.documentation, "The Python Tutorial", "python.org", "https://docs.python.org/3/tutorial/"),
               .r(.course, "Automate the Boring Stuff", "Al Sweigart", "https://automatetheboringstuff.com/"),
               .r(.practice, "Exercism Python Track", "Exercism", "https://exercism.org/tracks/python"),
           ]),
        .s("javascript", "JavaScript",
           "The language of the browser: closures, prototypes, async/await and the event loop.",
           .language, 40,
           res: [
               .r(.documentation, "The Modern JavaScript Tutorial", "javascript.info", "https://javascript.info/"),
               .r(.documentation, "JavaScript Reference", "MDN", "https://developer.mozilla.org/en-US/docs/Web/JavaScript"),
           ]),
        .s("typescript", "TypeScript",
           "Static typing for JavaScript: interfaces, generics and narrowing for safer code.",
           .language, 25, prereqs: ["javascript"],
           res: [
               .r(.documentation, "The TypeScript Handbook", "Microsoft", "https://www.typescriptlang.org/docs/handbook/intro.html"),
           ]),
        .s("java", "Java",
           "Strongly-typed OOP, the JVM, collections and exceptions.",
           .language, 45,
           res: [
               .r(.documentation, "Java Tutorials", "Oracle", "https://docs.oracle.com/javase/tutorial/"),
           ]),
        .s("kotlin", "Kotlin",
           "Modern, null-safe JVM language: data classes, extensions and lambdas.",
           .language, 35,
           res: [
               .r(.documentation, "Kotlin Koans", "JetBrains", "https://kotlinlang.org/docs/koans.html"),
               .r(.course, "Kotlin for Java Developers", "JetBrains Academy", "https://hyperskill.org/tracks"),
           ]),
        .s("swift", "Swift",
           "Optionals, value types, protocols and the idioms of Apple's modern language.",
           .language, 35,
           res: [
               .r(.documentation, "A Swift Tour", "Apple", "https://docs.swift.org/swift-book/"),
               .r(.practice, "100 Days of SwiftUI", "Hacking with Swift", "https://www.hackingwithswift.com/100/swiftui"),
           ]),
        .s("go", "Go",
           "Simple, fast, concurrent: goroutines, channels and the Go standard library.",
           .language, 30, prereqs: ["programming-fundamentals"],
           res: [
               .r(.documentation, "A Tour of Go", "go.dev", "https://go.dev/tour/"),
           ]),
        .s("bash-scripting", "Bash Scripting",
           "Automating machines: shell scripts, pipes and exit codes.",
           .tools, 10, prereqs: ["linux-basics"],
           res: [
               .r(.article, "Bash Guide", "GNU / Greg's Wiki", "https://mywiki.wooledge.org/BashGuide"),
           ]),
    ]

    // MARK: - Web

    static let web: [SkillSeed] = [
        .s("html-css", "HTML & CSS",
           "Semantic markup, the box model, flexbox and grid.",
           .web, 25,
           res: [
               .r(.documentation, "HTML & CSS Guides", "MDN", "https://developer.mozilla.org/en-US/docs/Learn_web_development"),
               .r(.practice, "CSS Battle", "CSS Battle", "https://cssbattle.dev/"),
           ]),
        .s("responsive-design", "Responsive Design",
           "Media queries, fluid layouts and mobile-first thinking.",
           .web, 12, prereqs: ["html-css"],
           res: [
               .r(.documentation, "Responsive Design", "MDN", "https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Responsive_Design"),
           ]),
        .s("dom-and-browser-apis", "DOM & Browser APIs",
           "Selecting nodes, handling events, forms, storage and fetch.",
           .web, 15, prereqs: ["javascript", "html-css"],
           res: [
               .r(.documentation, "Document Object Model", "MDN", "https://developer.mozilla.org/en-US/docs/Web/API/Document_Object_Model"),
           ]),
        .s("react", "React",
           "Components, props, state, hooks and the component lifecycle.",
           .web, 45, prereqs: ["javascript"],
           res: [
               .r(.documentation, "React Documentation", "react.dev", "https://react.dev/learn"),
               .r(.course, "React Course for Beginners", "freeCodeCamp", "https://www.youtube.com/watch?v=bMknfKXIFA8"),
           ]),
        .s("frontend-state-management", "Frontend State Management",
           "Lifting state, context, reducers and when to reach for a state library.",
           .web, 15, prereqs: ["react"],
           res: [
               .r(.documentation, "Managing State", "react.dev", "https://react.dev/learn/managing-state"),
           ]),
        .s("frontend-tooling", "Frontend Tooling",
           "Vite, ESLint, Prettier and npm scripts for a professional workflow.",
           .tools, 10, prereqs: ["javascript"],
           res: [
               .r(.documentation, "Vite Documentation", "vitejs.dev", "https://vitejs.dev/guide/"),
           ]),
        .s("accessibility-fundamentals", "Web Accessibility",
           "Semantic structure, ARIA, keyboard navigation and contrast.",
           .web, 8, prereqs: ["html-css"],
           res: [
               .r(.documentation, "Accessibility", "MDN", "https://developer.mozilla.org/en-US/docs/Web/Accessibility"),
               .r(.documentation, "WAI Tutorials", "W3C", "https://www.w3.org/WAI/tutorials/"),
           ]),
        .s("web-performance", "Web Performance",
           "Core Web Vitals, bundle size, lazy loading and profiling.",
           .web, 12, prereqs: ["react"],
           res: [
               .r(.documentation, "Web Performance", "MDN", "https://developer.mozilla.org/en-US/docs/Web/Performance"),
               .r(.practice, "PageSpeed Insights", "Google", "https://pagespeed.web.dev/"),
           ]),
        .s("node-js", "Node.js",
           "JavaScript on the server: modules, streams, npm and the event loop.",
           .web, 30, prereqs: ["javascript"],
           res: [
               .r(.documentation, "Node.js Learn", "nodejs.org", "https://nodejs.org/en/learn"),
           ]),
        .s("express", "Express",
           "Routing, middleware, request validation and error handling in Node.",
           .web, 15, prereqs: ["node-js"],
           res: [
               .r(.documentation, "Express Guide", "expressjs.com", "https://expressjs.com/en/starter/installing.html"),
           ]),
        .s("authentication-concepts", "Authentication & Authorization",
           "Sessions, JWTs, OAuth flows, hashing passwords and common pitfalls.",
           .web, 12, prereqs: ["rest-api-design"],
           res: [
               .r(.article, "JWT Introduction", "jwt.io", "https://jwt.io/introduction"),
               .r(.article, "OAuth 2.0 Simplified", "Aaron Parecki", "https://www.oauth.com/"),
           ]),
        .s("django", "Django",
           "Batteries-included Python web framework: ORM, admin, auth and forms.",
           .web, 25, prereqs: ["python"],
           res: [
               .r(.documentation, "Django Tutorial", "djangoproject.com", "https://docs.djangoproject.com/en/stable/intro/tutorial01/"),
           ]),
        .s("spring-boot", "Spring Boot",
           "Production-grade Java services: DI, data access, security and testing.",
           .web, 35, prereqs: ["java"],
           res: [
               .r(.documentation, "Spring Boot Guides", "spring.io", "https://spring.io/guides"),
           ]),
        .s("graphql", "GraphQL",
           "Schema-first APIs: queries, mutations, resolvers and clients.",
           .web, 15, prereqs: ["rest-api-design"],
           res: [
               .r(.documentation, "GraphQL Learn", "graphql.org", "https://graphql.org/learn/"),
           ]),
        .s("websockets-realtime", "Realtime & WebSockets",
           "Bidirectional connections, presence and scaling realtime features.",
           .web, 12, prereqs: ["http-and-apis"],
           res: [
               .r(.documentation, "WebSocket API", "MDN", "https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API"),
           ]),
    ]

    // MARK: - Mobile

    static let mobile: [SkillSeed] = [
        .s("swiftui", "SwiftUI",
           "Declarative UI for Apple platforms: views, state, layouts and navigation.",
           .mobile, 35, prereqs: ["swift"],
           res: [
               .r(.course, "SwiftUI Tutorials", "Apple", "https://developer.apple.com/tutorials/swiftui"),
               .r(.documentation, "SwiftUI Documentation", "Apple", "https://developer.apple.com/documentation/swiftui"),
           ]),
        .s("uikit", "UIKit",
           "The mature iOS toolkit: view controllers, Auto Layout and delegation.",
           .mobile, 30, prereqs: ["swift"],
           res: [
               .r(.documentation, "UIKit Documentation", "Apple", "https://developer.apple.com/documentation/uikit"),
           ]),
        .s("swift-concurrency", "Swift Concurrency",
           "async/await, actors, structured concurrency and MainActor.",
           .mobile, 15, prereqs: ["swift"],
           res: [
               .r(.documentation, "Swift Concurrency", "Apple", "https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/"),
               .r(.article, "Swift Concurrency by Example", "Hacking with Swift", "https://www.hackingwithswift.com/quick-start/concurrency"),
           ]),
        .s("ios-data-persistence", "iOS Data Persistence",
           "SwiftData, Core Data, UserDefaults and file storage on device.",
           .mobile, 15, prereqs: ["swift"],
           res: [
               .r(.documentation, "SwiftData Documentation", "Apple", "https://developer.apple.com/documentation/swiftdata"),
           ]),
        .s("ios-architecture-mvvm", "iOS Architecture (MVVM)",
           "Separating presentation from logic: MVVM, dependency injection and testability.",
           .mobile, 15, prereqs: ["swiftui"],
           res: [
               .r(.article, "MVVM in SwiftUI", "Swift with Majid", "https://swifwithmajid.com/"),
           ]),
        .s("ios-testing-debugging", "iOS Testing & Debugging",
           "XCTest, Swift Testing, breakpoints and Instruments basics.",
           .mobile, 12, prereqs: ["swift"],
           res: [
               .r(.documentation, "XCTest", "Apple", "https://developer.apple.com/documentation/xctest"),
           ]),
        .s("app-store-distribution", "App Store Distribution",
           "Certificates, provisioning, TestFlight and App Store review guidelines.",
           .mobile, 8, prereqs: ["swiftui"],
           res: [
               .r(.documentation, "App Store Connect Help", "Apple", "https://developer.apple.com/help/app-store-connect/"),
           ]),
        .s("android-sdk-fundamentals", "Android SDK Fundamentals",
           "Activities, intents, manifests and the Android app lifecycle.",
           .mobile, 30, prereqs: ["kotlin"],
           res: [
               .r(.course, "Android Basics with Compose", "Google", "https://developer.android.com/courses/android-basics-compose/course"),
           ]),
        .s("jetpack-compose", "Jetpack Compose",
           "Modern declarative Android UI: composables, state and layouts.",
           .mobile, 35, prereqs: ["kotlin"],
           res: [
               .r(.documentation, "Compose Pathway", "Google", "https://developer.android.com/compose"),
           ]),
        .s("kotlin-coroutines-flow", "Kotlin Coroutines & Flow",
           "Structured concurrency, suspend functions and reactive streams.",
           .mobile, 20, prereqs: ["kotlin"],
           res: [
               .r(.documentation, "Coroutines Guide", "JetBrains", "https://kotlinlang.org/docs/coroutines-guide.html"),
           ]),
        .s("android-architecture", "Android Architecture",
           "ViewModel, repositories, unidirectional data flow and Hilt basics.",
           .mobile, 18, prereqs: ["jetpack-compose", "android-sdk-fundamentals"],
           res: [
               .r(.documentation, "App Architecture Guide", "Google", "https://developer.android.com/topic/architecture"),
           ]),
        .s("room-persistence", "Room Persistence",
           "Local SQLite storage with compile-time verified queries.",
           .mobile, 12, prereqs: ["android-sdk-fundamentals"],
           res: [
               .r(.documentation, "Room", "Google", "https://developer.android.com/training/data-storage/room"),
           ]),
    ]

    // MARK: - Data & ML

    static let data: [SkillSeed] = [
        .s("spreadsheets", "Spreadsheets",
           "Formulas, lookups, pivot tables — the analyst's first tool.",
           .dataAndDatabases, 8,
           res: [
               .r(.course, "Google Sheets Training", "Google", "https://support.google.com/a/users/answer/9282959"),
           ]),
        .s("statistics", "Statistics & Probability",
           "Distributions, hypothesis testing, confidence intervals and correlation.",
           .dataScienceML, 30,
           res: [
               .r(.course, "Khan Academy Statistics", "Khan Academy", "https://www.khanacademy.org/math/statistics-probability"),
               .r(.book, "Think Stats", "Allen Downey", "https://greenteapress.com/wp/think-stats-2e/"),
           ]),
        .s("numpy", "NumPy",
           "Vectorised arrays, broadcasting and fast numerical computing.",
           .dataScienceML, 15, prereqs: ["python"],
           res: [
               .r(.documentation, "NumPy Absolute Beginner's Guide", "numpy.org", "https://numpy.org/doc/stable/user/absolute_beginners.html"),
           ]),
        .s("pandas", "Pandas",
           "DataFrames, joins, groupbys, cleaning and reshaping real datasets.",
           .dataScienceML, 20, prereqs: ["numpy"],
           res: [
               .r(.practice, "Kaggle Learn: Pandas", "Kaggle", "https://www.kaggle.com/learn/pandas"),
               .r(.documentation, "Pandas Getting Started", "pandas.pydata.org", "https://pandas.pydata.org/docs/getting_started/index.html"),
           ]),
        .s("data-visualization-python", "Data Visualisation (Python)",
           "Matplotlib and Seaborn: choosing and building honest charts.",
           .dataScienceML, 12, prereqs: ["pandas"],
           res: [
               .r(.practice, "Kaggle Learn: Data Visualization", "Kaggle", "https://www.kaggle.com/learn/data-visualization"),
           ]),
        .s("bi-tools", "BI Tools (Tableau / Power BI)",
           "Interactive dashboards and storytelling for stakeholders.",
           .dataAndDatabases, 15, prereqs: ["spreadsheets", "sql"],
           res: [
               .r(.course, "Tableau Training", "Tableau", "https://www.tableau.com/learn/training"),
               .r(.course, "Power BI Learning Path", "Microsoft", "https://learn.microsoft.com/en-us/training/powerplatform/power-bi"),
           ]),
        .s("data-warehousing", "Data Warehousing",
           "Star schemas, ETL/ELT and analytical modelling.",
           .dataAndDatabases, 20, prereqs: ["sql"],
           res: [
               .r(.article, "The Data Warehouse Toolkit (concepts)", "Kimball Group", "https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/"),
           ]),
        .s("exploratory-data-analysis", "Exploratory Data Analysis",
           "Profiling datasets, finding patterns and validating assumptions.",
           .dataScienceML, 15, prereqs: ["pandas", "statistics"],
           res: [
               .r(.book, "Exploratory Data Analysis with R", "Roger Peng", "https://bookdown.org/rdpeng/exdata/"),
           ]),
        .s("machine-learning", "Machine Learning",
           "Supervised and unsupervised learning, model selection and evaluation.",
           .dataScienceML, 50, prereqs: ["pandas", "statistics"],
           res: [
               .r(.course, "Machine Learning Specialization", "DeepLearning.AI / Coursera", "https://www.coursera.org/specializations/machine-learning-introduction", free: false),
               .r(.documentation, "scikit-learn User Guide", "scikit-learn", "https://scikit-learn.org/stable/user_guide.html"),
           ]),
        .s("feature-engineering", "Feature Engineering",
           "Encodings, scaling, leakage avoidance and feature selection.",
           .dataScienceML, 15, prereqs: ["machine-learning"],
           res: [
               .r(.practice, "Kaggle Learn: Feature Engineering", "Kaggle", "https://www.kaggle.com/learn/feature-engineering"),
           ]),
        .s("deep-learning", "Deep Learning",
           "Neural networks, backpropagation, CNN/RNN/transformer basics.",
           .dataScienceML, 45, prereqs: ["machine-learning"],
           res: [
               .r(.course, "Practical Deep Learning for Coders", "fast.ai", "https://course.fast.ai/"),
               .r(.documentation, "PyTorch Tutorials", "PyTorch", "https://pytorch.org/tutorials/"),
           ]),
        .s("nlp", "Natural Language Processing",
           "Tokenisation, embeddings, transformers and text pipelines.",
           .dataScienceML, 25, prereqs: ["deep-learning"],
           res: [
               .r(.course, "Hugging Face NLP Course", "Hugging Face", "https://huggingface.co/learn/nlp-course"),
           ]),
        .s("computer-vision", "Computer Vision",
           "Image classification, detection and transfer learning.",
           .dataScienceML, 25, prereqs: ["deep-learning"],
           res: [
               .r(.course, "CS231n Materials", "Stanford", "https://cs231n.github.io/"),
           ]),
        .s("mlops", "MLOps",
           "Experiment tracking, model packaging, deployment and monitoring.",
           .dataScienceML, 25, prereqs: ["machine-learning"], optionalPrereqs: ["docker"],
           res: [
               .r(.course, "MLOps Specialization", "DeepLearning.AI / Coursera", "https://www.coursera.org/specializations/mlops-machine-learning-duke", free: false),
           ]),
        .s("llm-fundamentals", "LLM Fundamentals",
           "How large language models work: tokens, context windows, fine-tuning.",
           .dataScienceML, 20, prereqs: ["deep-learning"],
           res: [
               .r(.course, "Hugging Face LLM Course", "Hugging Face", "https://huggingface.co/learn/llm-course"),
               .r(.article, "State of GPT", "Andrej Karpathy", "https://karpathy.ai/"),
           ]),
        .s("rag-and-vector-databases", "RAG & Vector Databases",
           "Retrieval-augmented generation, embeddings and vector stores.",
           .dataScienceML, 20, prereqs: ["llm-fundamentals"],
           res: [
               .r(.article, "Pinecone Learning Center", "Pinecone", "https://www.pinecone.io/learn/"),
           ]),
        .s("ai-agents-orchestration", "AI Agents & Orchestration",
           "Tool use, planning loops and multi-agent systems.",
           .dataScienceML, 18, prereqs: ["rag-and-vector-databases"],
           res: [
               .r(.course, "AI Agents Short Courses", "DeepLearning.AI", "https://www.deeplearning.ai/short-courses/"),
           ]),
        .s("prompt-engineering", "Prompt Engineering",
           "Structured prompts, few-shot patterns and evaluation.",
           .dataScienceML, 8, prereqs: ["llm-fundamentals"],
           res: [
               .r(.article, "Prompt Engineering Guide", "DAIR.AI", "https://www.promptingguide.ai/"),
           ]),
        .s("ab-testing-experimentation", "A/B Testing & Experimentation",
           "Designing experiments, sample sizes and reading results honestly.",
           .dataScienceML, 10, prereqs: ["statistics"],
           res: [
               .r(.article, "Evan's A/B Testing Handbook", "Evan Miller", "https://www.evanmiller.org/ab-testing/"),
           ]),
    ]

    // MARK: - Cloud, DevOps & Backend Infrastructure

    static let cloud: [SkillSeed] = [
        .s("cloud-fundamentals", "Cloud Fundamentals",
           "Regions, availability zones, shared responsibility and core service types.",
           .cloudDevOps, 20, prereqs: ["computer-networks", "linux-basics"],
           res: [
               .r(.course, "AWS Cloud Practitioner Essentials", "AWS", "https://aws.amazon.com/training/digital/aws-cloud-practitioner-essentials/"),
           ]),
        .s("aws-core-services", "AWS Core Services",
           "EC2, S3, RDS, VPC, IAM and Lambda — the workhorse services.",
           .cloudDevOps, 30, prereqs: ["cloud-fundamentals"],
           res: [
               .r(.documentation, "AWS Documentation", "AWS", "https://docs.aws.amazon.com/"),
               .r(.practice, "AWS Free Tier Labs", "AWS", "https://aws.amazon.com/free/"),
           ]),
        .s("terraform", "Terraform",
           "Infrastructure as code: providers, state, modules and plans.",
           .cloudDevOps, 20, prereqs: ["cloud-fundamentals"],
           res: [
               .r(.documentation, "Terraform Tutorials", "HashiCorp", "https://developer.hashicorp.com/terraform/tutorials"),
           ]),
        .s("docker", "Docker",
           "Images, containers, volumes and composing multi-service stacks.",
           .cloudDevOps, 20, prereqs: ["linux-basics"],
           res: [
               .r(.documentation, "Docker Getting Started", "Docker", "https://docs.docker.com/get-started/"),
           ]),
        .s("kubernetes", "Kubernetes",
           "Pods, deployments, services, ingress and cluster operations.",
           .cloudDevOps, 35, prereqs: ["docker"],
           res: [
               .r(.documentation, "Kubernetes Basics", "kubernetes.io", "https://kubernetes.io/docs/tutorials/kubernetes-basics/"),
           ]),
        .s("ci-cd-pipelines", "CI/CD Pipelines",
           "Automated build, test and deploy with GitHub Actions or GitLab CI.",
           .cloudDevOps, 20, prereqs: ["git-version-control", "docker"],
           res: [
               .r(.documentation, "GitHub Actions Documentation", "GitHub", "https://docs.github.com/en/actions"),
           ]),
        .s("monitoring-observability", "Monitoring & Observability",
           "Metrics, logs, traces, dashboards and alerting (Prometheus/Grafana).",
           .cloudDevOps, 15, prereqs: ["kubernetes"],
           res: [
               .r(.documentation, "Prometheus Docs", "prometheus.io", "https://prometheus.io/docs/introduction/overview/"),
           ]),
        .s("message-queues", "Message Queues",
           "Async processing with queues and brokers (Kafka, RabbitMQ, SQS).",
           .architecture, 15, prereqs: ["system-design-basics"],
           res: [
               .r(.article, "What is a Message Queue?", "IBM", "https://www.ibm.com/think/topics/message-queues"),
           ]),
        .s("microservices", "Microservices",
           "Service boundaries, API gateways and inter-service communication.",
           .architecture, 25, prereqs: ["system-design-basics", "docker"],
           res: [
               .r(.article, "Microservices Guide", "Martin Fowler", "https://martinfowler.com/microservices/"),
           ]),
        .s("caching-strategies", "Caching Strategies",
           "Redis, cache invalidation, TTLs and read/write patterns.",
           .architecture, 10, prereqs: ["dbms"],
           res: [
               .r(.documentation, "Redis Learn", "Redis", "https://redis.io/learn/"),
           ]),
        .s("security-fundamentals", "Security Fundamentals",
           "Threat models, least privilege, hashing, and the CIA triad.",
           .security, 20, prereqs: ["computer-networks"],
           res: [
               .r(.course, "TryHackMe Pre-Security", "TryHackMe", "https://tryhackme.com/room/presecurity"),
           ]),
    ]

    // MARK: - Security

    static let security: [SkillSeed] = [
        .s("cryptography", "Cryptography",
           "Symmetric vs asymmetric encryption, hashes, signatures and PKI.",
           .security, 18, prereqs: ["security-fundamentals"],
           res: [
               .r(.course, "Cryptography I", "Coursera / Stanford", "https://www.coursera.org/learn/crypto", free: false),
           ]),
        .s("owasp-web-security", "OWASP Web Security",
           "The OWASP Top 10: injection, XSS, broken auth and defences.",
           .security, 15, prereqs: ["security-fundamentals", "http-and-apis"],
           res: [
               .r(.documentation, "OWASP Top 10", "OWASP", "https://owasp.org/www-project-top-ten/"),
               .r(.practice, "OWASP WebGoat", "OWASP", "https://owasp.org/www-project-webgoat/"),
           ]),
        .s("penetration-testing", "Penetration Testing",
           "Recon, exploitation, privilege escalation and reporting.",
           .security, 30, prereqs: ["security-fundamentals", "linux-basics"],
           res: [
               .r(.practice, "TryHackMe", "TryHackMe", "https://tryhackme.com/"),
               .r(.practice, "Hack The Box", "Hack The Box", "https://www.hackthebox.com/"),
           ]),
        .s("siem-soc-tools", "SIEM & SOC Tools",
           "Log aggregation, detection rules and alert triage.",
           .security, 18, prereqs: ["security-fundamentals"],
           res: [
               .r(.course, "TryHackMe SOC Level 1", "TryHackMe", "https://tryhackme.com/path/outline/soclevel1"),
           ]),
        .s("incident-response", "Incident Response",
           "Preparation, containment, eradication and post-incident reviews.",
           .security, 15, prereqs: ["siem-soc-tools"],
           res: [
               .r(.documentation, "NIST SP 800-61 (Incident Handling)", "NIST", "https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final"),
           ]),
        .s("network-security", "Network Security",
           "Firewalls, IDS/IPS, VPNs and secure network design.",
           .security, 20, prereqs: ["computer-networks", "security-fundamentals"],
           res: [
               .r(.practice, "TryHackMe Network Security", "TryHackMe", "https://tryhackme.com/module/intro-to-network-security"),
           ]),
        .s("cloud-security", "Cloud Security",
           "IAM hardening, security groups, secrets and shared-responsibility in practice.",
           .security, 15, prereqs: ["aws-core-services", "security-fundamentals"],
           res: [
               .r(.documentation, "AWS Security Documentation", "AWS", "https://docs.aws.amazon.com/security/"),
           ]),
    ]

    // MARK: - QA

    static let qa: [SkillSeed] = [
        .s("test-automation", "Test Automation",
           "Automation frameworks, selectors, waits and maintainable suites.",
           .testing, 20, prereqs: ["software-testing-fundamentals", "programming-fundamentals"],
           res: [
               .r(.article, "Test Automation Patterns", "xUnit Patterns", "http://xunitpatterns.com/"),
           ]),
        .s("selenium", "Selenium",
           "Browser automation with WebDriver: locators, waits and page objects.",
           .testing, 20, prereqs: ["test-automation"],
           res: [
               .r(.documentation, "Selenium Documentation", "selenium.dev", "https://www.selenium.dev/documentation/"),
           ]),
        .s("api-testing", "API Testing",
           "Contract testing, auth flows and automated API assertions.",
           .testing, 12, prereqs: ["rest-api-design", "software-testing-fundamentals"],
           res: [
               .r(.practice, "Postman API Testing", "Postman Academy", "https://academy.postman.com/"),
           ]),
        .s("playwright", "Playwright",
           "Fast, reliable end-to-end testing across browsers.",
           .testing, 15, prereqs: ["test-automation", "javascript"],
           res: [
               .r(.documentation, "Playwright Docs", "playwright.dev", "https://playwright.dev/docs/intro"),
           ]),
        .s("performance-testing", "Performance Testing",
           "Load tests, percentiles, bottlenecks and capacity planning.",
           .testing, 12, prereqs: ["test-automation"],
           res: [
               .r(.documentation, "k6 Documentation", "Grafana k6", "https://grafana.com/docs/k6/latest/"),
           ]),
    ]
}
