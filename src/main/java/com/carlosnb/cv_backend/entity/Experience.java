package com.carlosnb.cv_backend.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDate;
import java.time.OffsetDateTime;

@Data
@Entity
@Table(name = "experiencia_laboral") 
public class Experience {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id; // En tu SQL es 'integer', no 'Long'

    // NOTA ARQUITECTÓNICA: 
    // Por ahora mapeamos las llaves foráneas como Integer simples para que compile rápido.
    // En la Fase 3 las cambiaremos por relaciones @ManyToOne con las entidades Persona y Empresa.
    @Column(name = "persona_id", nullable = false)
    private Integer personaId;

    @Column(name = "empresa_id", nullable = false)
    private Integer empresaId;

    @Column(nullable = false, length = 150)
    private String puesto;

    @Column(columnDefinition = "TEXT")
    private String descripcion;

    @Column(name = "fecha_inicio", nullable = false)
    private LocalDate fechaInicio;

    @Column(name = "fecha_fin")
    private LocalDate fechaFin;

    @Column(name = "es_actual", nullable = false)
    private Boolean esActual = false;

    @Column(nullable = false)
    private Boolean visible = true;

    @Column(nullable = false)
    private Short orden = 0;

    // Columnas de auditoría de tu SQL
    @Column(name = "creado_en", insertable = false, updatable = false)
    private OffsetDateTime creadoEn;

    @Column(name = "actualizado_en", insertable = false, updatable = false)
    private OffsetDateTime actualizadoEn;
}