package com.carlosnb.cv_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // Deshabilitamos CSRF para pruebas en APIs REST
            .authorizeHttpRequests(auth -> auth
                .anyRequest().permitAll() // Permitimos todas las peticiones sin autenticación temporalmente
            );
        
        return http.build();
    }
}