package com.carlosnb.cv_backend.controller.admin;

import com.carlosnb.cv_backend.dto.habilidad.HabilidadRequestDTO;
import com.carlosnb.cv_backend.dto.habilidad.HabilidadResponseDTO;
import com.carlosnb.cv_backend.service.HabilidadService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/habilidades")
@RequiredArgsConstructor
@CrossOrigin(origins = "*") // En producción restringir
public class HabilidadAdminController {

    private final HabilidadService habilidadService;

    @GetMapping
    public ResponseEntity<List<HabilidadResponseDTO>> listar() {
        return ResponseEntity.ok(habilidadService.listarTodas());
    }

    @PostMapping
    public ResponseEntity<HabilidadResponseDTO> crear(@Valid @RequestBody HabilidadRequestDTO request) {
        HabilidadResponseDTO creada = habilidadService.crear(request);
        return new ResponseEntity<>(creada, HttpStatus.CREATED);
    }
}