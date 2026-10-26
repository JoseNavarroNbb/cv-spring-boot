package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.OffsetDateTime;

@Data
@Entity
@Table(name = "sesion_visita")
public class SesionVisita {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cv_id", nullable = false)
    private Integer cvId;

    @Column(name = "visitante_hash", nullable = false, length = 64)
    private String visitanteHash;

    @Column(name = "iniciada_en", nullable = false)
    private OffsetDateTime iniciadaEn = OffsetDateTime.now();

    @Column(name = "pais_codigo", length = 2)
    private String paisCodigo;

    @Column(name = "dispositivo", nullable = false, length = 20)
    private String dispositivo = "OTRO";

    private String navegador;
    
    @Column(name = "sistema_operativo")
    private String sistemaOperativo;
    
    @Column(name = "origen_referencia")
    private String origenReferencia;

    @Column(name = "es_bot", nullable = false)
    private Boolean esBot = false;
}