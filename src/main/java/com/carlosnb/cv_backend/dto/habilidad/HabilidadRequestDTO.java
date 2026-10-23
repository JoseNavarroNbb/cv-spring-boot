package com.carlosnb.cv_backend.dto.habilidad;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

// DTO para recibir datos (POST/PUT)
@Data
public class HabilidadRequestDTO {
    @NotNull(message = "La categoría es obligatoria")
    private Short categoriaId;

    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    private String icono;
    private String sitioWeb;
    private Boolean activo;
}
