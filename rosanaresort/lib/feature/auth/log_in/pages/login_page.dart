import 'package:easy_localization/easy_localization.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/cache/cache_keys.dart';
import '../../../../core/dependencies/app_dependencies.dart';
import '../../../../core/theme/transelation/localization_cubit.dart';
import '../../../../core/theme/transelation/localization_key.dart';

import '../../validation/auth_validation.dart';
import '../../widget/auth_widgets.dart';
import '../cubit/login_cubit.dart';


class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    context.read<LoginCubit>().login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text, context: context,
        );
  }
@override
void initState() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<LoginCubit>().automaticLogin(context);
  });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);
    final userEmail =  deps.cache.getData(
        key: CacheKeys.userPhoneNumber)??"";
    final userNI =  deps.cache.getData(
        key: CacheKeys.userNationalId)??"";
    if(userNI != ""){
      _emailCtrl.text = "${userNI}";
    }
    if(userEmail != ""){
      _passwordCtrl.text = "${userEmail}";
    }
    return BlocListener<LoginCubit, LoginState>(
      listener: (context, state) {
        if (state.isSuccess) {
          // Navigate to home on success

        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AuthAppBar(
          actionLabel:  TranslationKey.signInTitle.tr(),
        ),
        body: BlocBuilder<LoginCubit, LoginState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 32.h),
                    AuthTextField(
                      label:  TranslationKey.nationalIdFieldTitle.tr(),
                      hint:  TranslationKey.nationalIdFieldHint.tr(),
                      controller: _emailCtrl,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.person_outline_rounded,
                      // validator: AuthValidation.validateEgyptianNationalId,
                      textInputAction: TextInputAction.next,
                      focusNode: _emailFocus,
                      onFieldSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_passwordFocus),
                    ),
                    SizedBox(height: 20.h),
                    AuthTextField(
                      label:  TranslationKey.phoneLabel.tr(),
                      hint:  TranslationKey.phoneFieldHint.tr(),
                      controller: _passwordCtrl,
                      prefixIcon: Icons.phone_android,
                       validator:AuthValidation.validateEgyptianPhone,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      focusNode: _passwordFocus,
                      onFieldSubmitted: (_) => _submit(context),

                    ),
                    SizedBox(height: 10.h),

                    AuthButton(
                      label: TranslationKey.signInTitle.tr(),
                      isLoading: state.isLoading,
                      onPressed: () => _submit(context),
                    ),
                    SizedBox(height: 24.h),


                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
