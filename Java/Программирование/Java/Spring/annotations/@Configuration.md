@Configuration
public class AppConfig {

    @Bean
    public UserService userService(UserRepository repo) {
        return new UserService(repo);
    }
}
Методы с @Bean создают бины, которые управляются Spring.

Можно использовать для подключения сторонних библиотек, которых нет в @Component.