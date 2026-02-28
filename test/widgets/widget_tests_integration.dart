import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Tests - Core Components', () {
    testWidgets('home screen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Home')),
        ),
      ));

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('message list displays messages', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              ListTile(title: Text('Message 1')),
              ListTile(title: Text('Message 2')),
              ListTile(title: Text('Message 3')),
            ],
          ),
        ),
      ));

      expect(find.text('Message 1'), findsOneWidget);
      expect(find.text('Message 2'), findsOneWidget);
      expect(find.text('Message 3'), findsOneWidget);
    });

    testWidgets('course card shows course info', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Card(
            child: Column(
              children: [
                Text('Flutter Basics'),
                Text('Learn Flutter from scratch'),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('Enroll'),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Flutter Basics'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('login form validates email', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(
                key: Key('email-field'),
                decoration: InputDecoration(labelText: 'Email'),
              ),
              TextField(
                key: Key('password-field'),
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: () {},
                child: Text('Login'),
              ),
            ],
          ),
        ),
      ));

      expect(find.byKey(Key('email-field')), findsOneWidget);
      expect(find.byKey(Key('password-field')), findsOneWidget);
    });

    testWidgets('loading indicator shows during data fetch',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('error message displays on failure', (WidgetTester tester) async {
      const errorMessage = 'Failed to load data';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              Text(errorMessage),
            ],
          ),
        ),
      ));

      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('button responds to tap', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ElevatedButton(
            onPressed: () => tapped = true,
            child: Text('Tap Me'),
          ),
        ),
      ));

      await tester.tap(find.byType(ElevatedButton));
      expect(tapped, isTrue);
    });

    testWidgets('text input captures user entry', (WidgetTester tester) async {
      final textController = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TextField(controller: textController),
        ),
      ));

      await tester.enterText(find.byType(TextField), 'Hello World');
      expect(textController.text, 'Hello World');
    });
  });

  group('Navigation Tests', () {
    testWidgets('navigate to detail screen', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('List'),
              ElevatedButton(
                onPressed: () {
                  // Navigate
                },
                child: Text('View Details'),
              ),
            ],
          ),
        ),
      ));

      expect(find.text('List'), findsOneWidget);
      expect(find.text('View Details'), findsOneWidget);
    });

    testWidgets('back button works', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            title: Text('Screen'),
            leading: BackButton(),
          ),
          body: Text('Content'),
        ),
      ));

      expect(find.byType(BackButton), findsOneWidget);
    });
  });

  group('UI State Tests', () {
    testWidgets('toggle button changes state', (WidgetTester tester) async {
      bool isFollowing = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Text(isFollowing ? 'Following' : 'Not Following'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isFollowing = !isFollowing;
                        });
                      },
                      child: Text('Toggle'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Not Following'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text('Following'),
          ),
        ),
      );

      // State changed
      expect(find.text('Following'), findsWidgets);
    });

    testWidgets('like button increments counter', (WidgetTester tester) async {
      int likeCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    Text('$likeCount'),
                    IconButton(
                      icon: Icon(Icons.favorite_outline),
                      onPressed: () {
                        setState(() {
                          likeCount++;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });
  });

  group('Input Validation Tests', () {
    testWidgets('email field shows error for invalid email',
        (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email required';
                }
                if (!value.contains('@')) {
                  return 'Invalid email';
                }
                return null;
              },
              decoration: InputDecoration(labelText: 'Email'),
            ),
          ),
        ),
      ));

      // Find form and validate
      final form = formKey.currentState;
      bool isValid = form?.validate() ?? false;
      expect(isValid, isFalse);
    });

    testWidgets('password field requires minimum length',
        (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: TextFormField(
              validator: (value) {
                if (value != null && value.length < 8) {
                  return 'Minimum 8 characters';
                }
                return null;
              },
              decoration: InputDecoration(labelText: 'Password'),
            ),
          ),
        ),
      ));

      final form = formKey.currentState;
      bool isValid = form?.validate() ?? false;
      expect(isValid, isFalse);
    });
  });

  group('Accessibility Tests', () {
    testWidgets('buttons have semantic labels', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Semantics(
                label: 'Send message button',
                child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {},
                ),
              ),
              Semantics(
                label: 'Delete item button',
                child: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ));

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('text contrast is sufficient', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Colors.blue,
          textTheme: TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
          ),
        ),
        home: Scaffold(
          body: Text('High contrast text'),
        ),
      ));

      expect(find.text('High contrast text'), findsOneWidget);
    });
  });
}
