package com.carlosnb.cv_backend.controller.public_api;

import com.carlosnb.cv_backend.dto.CvCompletoDTO;
import com.carlosnb.cv_backend.entity.Cv;
import com.carlosnb.cv_backend.entity.Persona;
import com.carlosnb.cv_backend.exception.ResourceNotFoundException;
import com.carlosnb.cv_backend.repository.CvRepository;
import com.carlosnb.cv_backend.repository.PersonaRepository;
import com.carlosnb.cv_backend.service.AnaliticaService;

import jakarta.servlet.http.HttpServletRequest;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.scheduling.annotation.EnableAsync; 

@RestController
@RequestMapping("/api/v1/public/cv")
@CrossOrigin(origins = "*")
@EnableAsync
public class PublicCvController {

    private final CvRepository cvRepository;
    private final PersonaRepository personaRepository;
    private final AnaliticaService analiticaService;

    PublicCvController(CvRepository cvRepository, PersonaRepository personaRepository, AnaliticaService analiticaService) {
        this.cvRepository = cvRepository;
        this.personaRepository = personaRepository;
        this.analiticaService = analiticaService;
    }

    @GetMapping("/{slug}")
    public ResponseEntity<CvCompletoDTO> getFullCv(@PathVariable String slug, HttpServletRequest request) {
        
        Cv cv = cvRepository.findBySlug(slug);
        if (cv == null) {
            throw new ResourceNotFoundException("CV no encontrado");
        }

        analiticaService.registrarVisitaYCvVisto(cv.getId(), request);

        // 1. Traemos la persona CON sus experiencias
        Persona persona = personaRepository.findPersonaWithExperiencias(cv.getPersonaId())
                .orElseThrow(() -> new ResourceNotFoundException("Persona no encontrada"));

        // 2. Traemos la MISMA persona (en otra consulta) CON sus proyectos
        // y se los asignamos al objeto persona que ya tenemos en memoria.
        Persona personaConProyectos = personaRepository.findPersonaWithProyectos(cv.getPersonaId())
                .orElseThrow(() -> new ResourceNotFoundException("Persona no encontrada"));
        
        persona.setProyectos(personaConProyectos.getProyectos());

        // 3. Armamos el DTO (Ahora persona ya tiene ambas listas cargadas)
        CvCompletoDTO dto = new CvCompletoDTO();
        dto.setNombreCompleto(persona.getNombreCompleto());
        dto.setTitular(cv.getTitular());
        dto.setResumenProfesional(cv.getResumenProfesional());
        dto.setUrlPdf(cv.getUrlPdf());
        dto.setExperiencias(persona.getExperiencias());
        dto.setProyectos(persona.getProyectos());
        dto.setPersona(persona);

        return ResponseEntity.ok(dto);
    }
}