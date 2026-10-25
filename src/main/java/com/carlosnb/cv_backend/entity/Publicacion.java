package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;

@Data
@Entity
@Table(name = "publicacion")
public class Publicacion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    @Column(name = "persona_id")
    private Integer personaId;
    private String titulo;
    private String medio;
    private String referencia;
    @Column(name = "fecha_publicacion")
    private LocalDate fechaPublicacion;
}