import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/app_state.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../data/mock_data.dart';
import '../widgets/common.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ContentWidth(
          maxWidth: 520,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Align(alignment: Alignment.centerLeft, child: CampusXMark()),
                const Spacer(),
                Container(
                  width: 250,
                  height: 250,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: CampusColors.primary.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🎓', style: TextStyle(fontSize: 112)),
                ),
                const SizedBox(height: 36),
                Text(
                  'Your campus.\nEverything. Connected.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Buy and sell, find a room, discover opportunities, book services and unlock student deals from one place.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const Spacer(),
                FilledButton(onPressed: () => context.go('/auth'), child: const Text('Get started')),
                const SizedBox(height: 10),
                TextButton(onPressed: () => context.go('/auth'), child: const Text('I already have an account')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool creating = false;
  bool obscure = true;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void continueFlow() {
    FocusScope.of(context).unfocus();
    context.go('/university');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ContentWidth(
          maxWidth: 480,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CampusXMark(),
              const SizedBox(height: 36),
              Text(
                creating ? 'Create your account' : 'Welcome back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(creating ? 'Let’s get your campus life connected.' : 'Sign in to continue to CampusX.'),
              const SizedBox(height: 28),
              if (creating) ...[
                TextField(
                  controller: nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline_rounded)),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: emailController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email or phone number', prefixIcon: Icon(Icons.alternate_email_rounded)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                onSubmitted: (_) => continueFlow(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: continueFlow, child: Text(creating ? 'Create account' : 'Sign in')),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: continueFlow,
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continue with Google'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: continueFlow,
                icon: const Icon(Icons.apple_rounded),
                label: const Text('Continue with Apple'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => creating = !creating),
                  child: Text(creating ? 'Already have an account? Sign in' : 'New to CampusX? Create account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UniversityScreen extends ConsumerStatefulWidget {
  const UniversityScreen({super.key});

  @override
  ConsumerState<UniversityScreen> createState() => _UniversityScreenState();
}

class _UniversityScreenState extends ConsumerState<UniversityScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(campusProvider.select((state) => state.university));
    final visible = universities.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Select your university')),
      body: ContentWidth(
        maxWidth: 620,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('This helps CampusX personalize listings, housing, events and deals around you.', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 18),
              TextField(
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(hintText: 'Search university', prefixIcon: Icon(Icons.search_rounded)),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final university = visible[index];
                    final active = selected == university;
                    return Card(
                      child: RadioListTile<String>(
                        value: university,
                        groupValue: selected,
                        onChanged: (value) {
                          if (value != null) ref.read(campusProvider.notifier).setUniversity(value);
                        },
                        title: Text(university, style: const TextStyle(fontWeight: FontWeight.w700)),
                        secondary: CircleAvatar(
                          backgroundColor: active ? CampusColors.primary : CampusColors.primary.withAlpha(18),
                          foregroundColor: active ? Colors.white : CampusColors.primary,
                          child: const Icon(Icons.school_outlined),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(onPressed: () => context.go('/interests'), child: const Text('Continue')),
            ],
          ),
        ),
      ),
    );
  }
}

class InterestsScreen extends ConsumerStatefulWidget {
  const InterestsScreen({super.key});

  @override
  ConsumerState<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends ConsumerState<InterestsScreen> {
  late Set<String> selected;

  @override
  void initState() {
    super.initState();
    selected = Set<String>.of(ref.read(campusProvider).interests);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your interests')),
      body: ContentWidth(
        maxWidth: 700,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What are you interested in?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              const Text('Choose anything you want CampusX to prioritize. You can change this later.'),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.35,
                  children: [
                    for (final kind in ListingKind.values)
                      ChoiceChip(
                        selected: selected.contains(kind.name),
                        showCheckmark: true,
                        label: SizedBox.expand(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(kind.emoji, style: const TextStyle(fontSize: 28)),
                              const SizedBox(height: 6),
                              Text(kind.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        onSelected: (value) {
                          setState(() => value ? selected.add(kind.name) : selected.remove(kind.name));
                        },
                      ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () {
                  ref.read(campusProvider.notifier)
                    ..setInterests(selected)
                    ..finishOnboarding();
                  context.go('/app');
                },
                child: const Text('Enter CampusX'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
