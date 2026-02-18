@Service
public class UserService {

    @Autowired
    private UserRepository userRepository; // Spring сам внедрит бин

    public void printAllUsers() {
        userRepository.findAll().forEach(System.out::println);
    }
}
Можно использовать на конструкторе:

java
Копировать код
@Service
public class UserService {
    private final UserRepository userRepository;

    @Autowired
    public UserService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }
}
Рекомендуется использовать конструкторное внедрение, это делает код тестируемым.