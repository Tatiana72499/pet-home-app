import 'package:flutter/material.dart';
import 'package:pethome_app/src/features/auth/data/auth_service.dart';
import 'package:pethome_app/src/features/auth/domain/auth_user.dart';
import 'package:pethome_app/src/features/home/presentation/pages/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    required this.authService,
  });

  final AuthService authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  List<PublicVeterinaria> _veterinarias = <PublicVeterinaria>[];
  String? _selectedSlugVeterinaria;

  bool _isLoading = false;
  bool _isLoadingVets = true;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadVeterinarias();
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadVeterinarias() async {
    setState(() {
      _isLoadingVets = true;
      _errorMessage = null;
    });

    try {
      final vets = await widget.authService.getPublicVeterinarias();
      if (!mounted) return;
      setState(() {
        _veterinarias = vets;
        _selectedSlugVeterinaria = vets.isEmpty ? null : vets.first.slug;
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'No se pudo cargar veterinarias.');
    } finally {
      if (mounted) {
        setState(() => _isLoadingVets = false);
      }
    }
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'El correo es obligatorio';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo valido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';

    if (password.isEmpty) {
      return 'La contrasena es obligatoria';
    }

    if (password.length < 6) {
      return 'Minimo 6 caracteres';
    }

    if (password.contains(' ')) {
      return 'No debe contener espacios';
    }

    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_selectedSlugVeterinaria == null || _selectedSlugVeterinaria!.isEmpty) {
      setState(() {
        _errorMessage = 'Selecciona una veterinaria para continuar.';
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final AuthSession session = await widget.authService.login(
        correo: _correoController.text.trim(),
        password: _passwordController.text,
        slugVeterinaria: _selectedSlugVeterinaria!,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(
            authService: widget.authService,
            initialUser: session.user,
          ),
        ),
      );
    } on AuthException catch (error) {
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'No se pudo iniciar sesion. Revisa el servidor.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6A11CB), Color(0xFF8E2DE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _Header(),
                  const SizedBox(height: 30),
                  _LoginCard(
                    formKey: _formKey,
                    correoController: _correoController,
                    passwordController: _passwordController,
                    veterinarias: _veterinarias,
                    selectedSlugVeterinaria: _selectedSlugVeterinaria,
                    isLoading: _isLoading,
                    isLoadingVets: _isLoadingVets,
                    showPassword: _showPassword,
                    errorMessage: _errorMessage,
                    onRetryVets: _loadVeterinarias,
                    onChangedVeterinaria: (value) {
                      setState(() => _selectedSlugVeterinaria = value);
                    },
                    onTogglePassword: () {
                      setState(() {
                        _showPassword = !_showPassword;
                      });
                    },
                    onSubmit: _submit,
                    validateEmail: _validateEmail,
                    validatePassword: _validatePassword,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 35,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Pet Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Cuidamos a los que mas quieres',
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.correoController,
    required this.passwordController,
    required this.veterinarias,
    required this.selectedSlugVeterinaria,
    required this.isLoading,
    required this.isLoadingVets,
    required this.showPassword,
    required this.errorMessage,
    required this.onRetryVets,
    required this.onChangedVeterinaria,
    required this.onTogglePassword,
    required this.onSubmit,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController correoController;
  final TextEditingController passwordController;
  final List<PublicVeterinaria> veterinarias;
  final String? selectedSlugVeterinaria;
  final bool isLoading;
  final bool isLoadingVets;
  final bool showPassword;
  final String? errorMessage;
  final VoidCallback onRetryVets;
  final ValueChanged<String?> onChangedVeterinaria;
  final VoidCallback onTogglePassword;
  final VoidCallback onSubmit;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenido',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A11CB),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Inicia sesion para continuar',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text('Veterinaria'),
              const SizedBox(height: 8),
              if (isLoadingVets)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (veterinarias.isEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: onRetryVets,
                    child: const Text('Reintentar carga de veterinarias'),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedSlugVeterinaria,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.local_hospital_outlined),
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: veterinarias
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item.slug,
                          child: Text(item.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: onChangedVeterinaria,
                ),
              const SizedBox(height: 16),
              const Text('Correo'),
              const SizedBox(height: 8),
              TextFormField(
                controller: correoController,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Contrasena'),
              const SizedBox(height: 8),
              TextFormField(
                controller: passwordController,
                obscureText: !showPassword,
                validator: validatePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: onTogglePassword,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : onSubmit,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Entrar'),
              ),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('o'),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Crear cuenta nueva'),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
