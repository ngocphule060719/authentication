abstract class AppNavigator {
  void toHome();

  void toLogin();

  void toRegister();

  void popWithResult<T>(T result);

  void pop();
}
