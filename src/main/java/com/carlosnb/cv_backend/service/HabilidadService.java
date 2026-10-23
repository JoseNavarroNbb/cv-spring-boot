package com.carlosnb.cv_backend.service;

import com.carlosnb.cv_backend.dto.habilidad.HabilidadRequestDTO;
import com.carlosnb.cv_backend.dto.habilidad.HabilidadResponseDTO;
import com.carlosnb.cv_backend.entity.CategoriaHabilidad;
import com.carlosnb.cv_backend.entity.Habilidad;
import com.carlosnb.cv_backend.mapper.HabilidadMapper;
import com.carlosnb.cv_backend.repository.CategoriaHabilidadRepository;
import com.carlosnb.cv_backend.repository.HabilidadRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class HabilidadService {

    private final HabilidadRepository habilidadRepository;
    private final CategoriaHabilidadRepository categoriaRepository; // inyectado automáticamente por Spring

    @Transactional(readOnly = true)
    public List<HabilidadResponseDTO> listarTodas() {
        return habilidadRepository.findAll()
                .stream()
                .map(HabilidadMapper::toResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public HabilidadResponseDTO crear(HabilidadRequestDTO request) {
        // 1. Buscamos la categoría en la BD. Si no existe, lanzamos error.
        // (El equivalente a Categoria::findOrFail($id) en Laravel)
        CategoriaHabilidad categoria = categoriaRepository.findById(request.getCategoriaId())
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada"));

        // 2. Convertimos el DTO a Entidad
        Habilidad nueva = HabilidadMapper.toEntity(request);
        
        // 3. Le asignamos la categoría encontrada
        nueva.setCategoria(categoria);

        // 4. Guardamos
        Habilidad guardada = habilidadRepository.save(nueva);
        
        return HabilidadMapper.toResponse(guardada);
    }
}