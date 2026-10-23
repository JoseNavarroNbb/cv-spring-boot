package com.carlosnb.cv_backend.dto.habilidad;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

// DTO para devolver datos (GET)
@Data
public class HabilidadResponseDTO {
    private Integer id;
    private String nombre;
    private String icono;
    private String sitioWeb;
    private Boolean activo;
    private String nombreCategoria; // Aplanamos la relación
}
