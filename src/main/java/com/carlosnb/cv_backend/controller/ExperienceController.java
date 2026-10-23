package com.carlosnb.cv_backend.controller;

import com.carlosnb.cv_backend.entity.Experience;
import com.carlosnb.cv_backend.service.ExperienceService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/experiences")
@CrossOrigin(origins = "*")
public class ExperienceController {

    private final ExperienceService experienceService;

    public ExperienceController(ExperienceService experienceService) {
        this.experienceService = experienceService;
    }

    @GetMapping
    public List<Experience> getAll() {
        return experienceService.getAllExperiences();
    }

    @PostMapping
    public Experience create(@RequestBody Experience experience) {
        return experienceService.saveExperience(experience);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Integer id) { 
        if (experienceService.getExperienceById(id).isPresent()) {
            experienceService.deleteExperience(id);
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }
}