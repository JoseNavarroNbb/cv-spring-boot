package com.carlosnb.cv_backend.dto;

import com.carlosnb.cv_backend.entity.Experience;
import com.carlosnb.cv_backend.entity.Persona;
import com.carlosnb.cv_backend.entity.Proyecto;
import lombok.Data;
import java.util.List;

@Data
public class CvCompletoDTO {
    private String nombreCompleto;
    private Persona persona; 
    private String titular;
    private String resumenProfesional;
    private String urlPdf;


    
    private List<Experience> experiencias;
    private List<Proyecto> proyectos;
}