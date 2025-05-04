import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stranger_link_app/blocs/auth/auth_bloc.dart';
import 'package:stranger_link_app/blocs/profile/profile_bloc.dart';
import 'package:stranger_link_app/blocs/registration/register_bloc.dart';
import 'package:stranger_link_app/repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  final String? errorMessage;

  const RegisterScreen({Key? key, this.errorMessage}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _termsAccepted = false;
  bool _showTerms = false;

  @override
  void initState() {
    super.initState();
    // Mostra il messaggio di errore se presente
    if (widget.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Devi accettare i termini e le condizioni per procedere'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      context.read<RegisterBloc>().add(RegisterSubmitted(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  void _showTermsAndConditions() {
    setState(() {
      _showTerms = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(
        authRepository: context.read<AuthRepository>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registrazione'),
        ),
        body: BlocListener<RegisterBloc, RegisterState>(
          listener: (context, state) {
            if (state is RegisterFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is UsernameAlreadyExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Username già in uso. Scegli un altro username.'),
                  backgroundColor: Colors.red,
                ),
              );
              // Focus sullo username per facilitare la modifica
              FocusScope.of(context).requestFocus();
            } else if (state is EmailAlreadyExists) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email già registrata. Prova ad accedere o usa un\'altra email.'),
                  backgroundColor: Colors.red,
                ),
              );
            } else if (state is RegisterSuccess) {
              // Aggiorna l'AuthBloc
              context.read<AuthBloc>().add(AppStarted());

              // Carica il profilo
              context.read<ProfileBloc>().add(FetchProfile());
              // Imposta esplicitamente la modalità di modifica del profilo
              context.read<ProfileBloc>().add(const SetEditMode(isEditing: true));


              // Naviga alla schermata del profilo
              Navigator.pushReplacementNamed(context, '/profile');
            } else if (state is TermsAndConditionsAccepted) {
              setState(() {
                _termsAccepted = state.accepted;
              });
            }
          },
          child: _showTerms
              ? _buildTermsScreen()
              : _buildRegistrationForm(context),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(BuildContext context) {
    return BlocBuilder<RegisterBloc, RegisterState>(
      builder: (context, state) {
        if (state is RegisterLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci uno username';
                    }
                    if (value.length < 3) {
                      return 'Lo username deve contenere almeno 3 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci un indirizzo email';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Inserisci un indirizzo email valido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Inserisci una password';
                    }
                    if (value.length < 6) {
                      return 'La password deve contenere almeno 6 caratteri';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Conferma Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Conferma la password';
                    }
                    if (value != _passwordController.text) {
                      return 'Le password non coincidono';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        context.read<RegisterBloc>().add(TermsAccepted(value ?? false));
                      },
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                          children: [
                            const TextSpan(text: 'Accetto i '),
                            TextSpan(
                              text: 'Termini e Condizioni',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()..onTap = _showTermsAndConditions,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _register(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Registrati'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Hai già un account? Accedi'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsScreen() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Termini e Condizioni',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1. Introduzione',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Benvenuto in StrangerLink. Utilizzando questa applicazione, l\'utente accetta di rispettare i seguenti termini e condizioni. Si prega di leggerli attentamente.',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '2. Utilizzo dell\'applicazione',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'StrangerLink è un\'applicazione di messaggistica che consente agli utenti di connettersi con persone sconosciute. L\'utente si impegna a utilizzare l\'applicazione in modo responsabile, senza violare leggi o danneggiare altri utenti.',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '3. Registrazione e Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Per utilizzare StrangerLink, è necessario registrarsi fornendo informazioni accurate e aggiornate. L\'utente è responsabile della sicurezza del proprio account e di tutte le attività che vi si svolgono.',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '4. Contenuti',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'L\'utente è l\'unico responsabile dei contenuti che pubblica tramite l\'applicazione. Non è consentito pubblicare contenuti illegali, offensivi, diffamatori o che violino i diritti di terzi.',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '5. Privacy',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'La nostra Informativa sulla Privacy descrive come raccogliamo, utilizziamo e proteggiamo i dati dell\'utente. Utilizzando StrangerLink, l\'utente acconsente al trattamento dei propri dati come descritto nell\'Informativa sulla Privacy.',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '6. Modifiche ai Termini',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ci riserviamo il diritto di modificare questi termini in qualsiasi momento. Le modifiche saranno effettive non appena pubblicate nell\'applicazione. Continuando a utilizzare l\'applicazione dopo tali modifiche, l\'utente accetta i nuovi termini.',
                  ),
                  const SizedBox(height: 16),

                  Text(
                    '7. Recesso',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'L\'utente può interrompere l\'utilizzo dell\'applicazione in qualsiasi momento. Ci riserviamo il diritto di sospendere o terminare l\'accesso dell\'utente all\'applicazione in caso di violazione dei presenti termini.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showTerms = false;
                  });
                },
                child: const Text('Torna alla registrazione'),
              ),
              FilledButton(
                onPressed: () {
                  context.read<RegisterBloc>().add(const TermsAccepted(true));
                  setState(() {
                    _showTerms = false;
                  });
                },
                child: const Text('Accetto'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}