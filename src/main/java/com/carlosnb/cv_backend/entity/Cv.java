package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "cv")
public class Cv {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;
    @Column(name = "persona_id")
    private Integer personaId;
    private String slug;
    private String titulo;
    private String titular;
    @Column(name = "resumen_profesional", columnDefinition = "TEXT")
    private String resumenProfesional;
    @Column(name = "url_pdf")
    private String urlPdf;
}