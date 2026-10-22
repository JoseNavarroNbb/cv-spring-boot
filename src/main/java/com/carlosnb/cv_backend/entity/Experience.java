package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Data // Anotación de Lombok que genera getters, setters y toString automáticamente
@Entity
@Table(name = "experiences")
public class Experience {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String company;
    private String role;
    
    @Column(columnDefinition = "TEXT")
    private String description;
    
    private LocalDate startDate;
    private LocalDate endDate;
}