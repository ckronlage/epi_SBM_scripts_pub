set(0,'DefaultFigureWindowStyle','docked')

clear;
close all;
hold on

n_sims = 3;
n_vertices = 10000;
n_controlsubjects = 94;
n_lesionalsubjects = 27;
phi = 0.2;

for sim = 1:n_sims

    AFROC = [];
    
    rand_marks_control = rand(n_vertices,n_controlsubjects);
    rand_marks_lesional = rand(n_vertices,n_lesionalsubjects);
    
    mark_threshold_start=0.01/(n_vertices);
    mark_threshold_end=10/(n_vertices);
    mark_threshold_step =1.05;
    
    mark_threshold = mark_threshold_start;
    while (mark_threshold < mark_threshold_end)
        marks_control = rand_marks_control < mark_threshold;
        marks_lesional = rand_marks_lesional < mark_threshold;
    
        TPCount = 0;
        FPSubjectCount = 0;
    
        for i = 1:n_controlsubjects        
            if any(marks_control(:,i),'all')
                FPSubjectCount = FPSubjectCount + 1;
            end
        end
    
        for i = 1:n_lesionalsubjects
            if any(marks_lesional(1:(n_vertices*phi),i),'all')
                TPCount = TPCount + 1;
            end
        end
    
        TPF = TPCount / n_lesionalsubjects;
        FPF = FPSubjectCount / n_controlsubjects;
       
        AFROC(end+1,:) = [TPF,FPF];
    
        mark_threshold = mark_threshold*mark_threshold_step;
    end
    
    p = plot(AFROC(:,2),AFROC(:,1),'LineWidth',1.5);
    p.Color(4) = 0.8;
    %p = area(AFROC(:,2),AFROC(:,1));
    %p.FaceAlpha = 0.5;

end


x_plot = 0:0.01:1;
y_plot = 1 - (1 - x_plot).^phi;
plot(x_plot,y_plot,'LineWidth',1.0,'LineStyle','--','Color','black');
hold off
axis equal
axis([0 1 0 1])