package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "categoria_habilidad")
@Getter @Setter @NoArgsConstructor @AllArgsConstructor @Builder
public class CategoriaHabilidad {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Short id; // Usamos Short porque en tu SQL es 'smallint'

    @Column(nullable = false, length = 60, unique = true)
    private String nombre;

    @Column(nullable = false)
    private Short orden = 0;
}