@Bean
public JwtService jwtService(@Value("${jwt.secret}") String secret) {
    return new DefaultJwtService(secret, 3600);
}
Отличие от @Component: @Bean создаётся вручную в коде, [[@Component ]]— автоматически при сканировании пакетов.