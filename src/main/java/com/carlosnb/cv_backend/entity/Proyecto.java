package com.carlosnb.cv_backend.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "proyecto")
public class Proyecto {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "persona_id", nullable = false)
    @JsonBackReference
    private Persona persona;

    private String nombre;
    @Column(columnDefinition = "TEXT")
    private String descripcion;
    @Column(name = "es_destacado")
    private Boolean esDestacado;
    private Boolean visible;
}