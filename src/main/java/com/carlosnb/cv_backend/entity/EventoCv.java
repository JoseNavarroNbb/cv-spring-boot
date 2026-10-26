package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.OffsetDateTime;

@Data
@Entity
@Table(name = "evento_cv")
public class EventoCv {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "sesion_visita_id", nullable = false)
    private Long sesionVisitaId;

    @Column(name = "tipo_evento_id", nullable = false)
    private Short tipoEventoId;

    @Column(name = "elemento_tipo", length = 30)
    private String elementoTipo;

    @Column(name = "elemento_id")
    private Integer elementoId;

    private String etiqueta;

    @Column(name = "ocurrio_en", nullable = false)
    private OffsetDateTime ocurrioEn = OffsetDateTime.now();
}