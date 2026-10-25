package com.carlosnb.cv_backend.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.web.SecurityFilterChain;
import static org.springframework.security.config.Customizer.withDefaults;

@Configuration
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // Deshabilitamos CSRF para pruebas en APIs REST
            .authorizeHttpRequests(auth -> auth
                // Permitimos el acceso libre únicamente a tus endpoints públicos
                .requestMatchers("/api/v1/public/**").permitAll()
                // Cualquier otro endpoint (como los de administrador o gestión) requerirá autenticación
                .anyRequest().authenticated()
            )
            // Habilitamos HTTP Basic por si quieres proteger rutas y probarlas con usuario/contraseña básicos
            .httpBasic(withDefaults());
        
        return http.build();
    }
}