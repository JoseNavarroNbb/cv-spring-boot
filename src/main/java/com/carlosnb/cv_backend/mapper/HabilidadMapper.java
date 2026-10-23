package com.carlosnb.cv_backend.mapper;

import com.carlosnb.cv_backend.dto.habilidad.HabilidadRequestDTO;
import com.carlosnb.cv_backend.dto.habilidad.HabilidadResponseDTO;
import com.carlosnb.cv_backend.entity.Habilidad;

public class HabilidadMapper {

    public static HabilidadResponseDTO toResponse(Habilidad entity) {
        if (entity == null) return null;
        HabilidadResponseDTO dto = new HabilidadResponseDTO();
        dto.setId(entity.getId());
        dto.setNombre(entity.getNombre());
        dto.setIcono(entity.getIcono());
        dto.setSitioWeb(entity.getSitioWeb());
        dto.setActivo(entity.getActivo());
        if (entity.getCategoria() != null) {
            dto.setNombreCategoria(entity.getCategoria().getNombre());
        }
        return dto;
    }

    public static Habilidad toEntity(HabilidadRequestDTO dto) {
        Habilidad entity = new Habilidad();
        entity.setNombre(dto.getNombre());
        entity.setIcono(dto.getIcono());
        entity.setSitioWeb(dto.getSitioWeb());
        entity.setActivo(dto.getActivo() != null ? dto.getActivo() : true);
        // Nota: La categoría se setea en el Servicio
        return entity;
    }
}