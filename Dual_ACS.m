%Dual-ACS
clc
clear all

%A feladatot nem teljesen veletlenul' generaljuk
rand('twister', 4022)
%nccity: 4017 (% Within 24 hours at 60 mph)
%uscity: 4009, 4010, 4015 (20-21-22), 4022 (20), de 4 törés, 4029 megint 3mas, 5035
%is jó (% Within 2 hours at 35 mph)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameterek a VRPTW feladathoz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  XY = uscity('XY');
  XY = XY(dists(XY(1,:),XY,'mi')/35 < 2, :);  % Within 24 hours at 35 mph
  num_of_cities = size(XY,1);
  distance_matrix = dists(XY,XY,'mi')/35;
  customer_demands = [0 10*ones(1,num_of_cities-1)];
  vehicle_cap = 100;
  load_time = 12/60;
  B = floor(rand(num_of_cities-1,1)*10)+7;
  TimeWindow = [B B+floor(rand(num_of_cities-1,1)*6)+1];
  clear B
  TimeWindow = [-inf inf;TimeWindow;-inf inf];

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %Clarke-Wright Saving Alg.
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  loc = vrpsavings(distance_matrix,{customer_demands,vehicle_cap},{load_time,TimeWindow});

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %Az algoritmus kiertekelese: megkapjuk a teljes hosszt es a jarmuvek
  %szamat, tovabba kiegeszito adatokat 
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %TC = Total Cost, XFlg = feasible megoldas-e, ha nem miert nem az
  %out = reszletes kiegeszito adatok a megoldasrol
  [TC,XFlg,out] = locTC(loc,distance_matrix,{customer_demands,vehicle_cap},{load_time,TimeWindow});
  clear XFlg

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Parameterek az ACS_Vehicle es ACS_Time algoritmusokhoz
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

num_of_ants = 10;
beta = 3;
gamma = 0.1;
rho = 0.01;
q0 = 0.9;

stopeval = 6;

%Kezdo osszkoltseg a Clarke-Wright alg.-bol
Initial_TC = sum(TC);
Initial_fleet = length(TC);

CW_best = sprintf('A CW Savings (%d) jarmuvet talalt minimumnak, (%5.1f) teljes koltseggel', Initial_fleet, Initial_TC);
disp(CW_best);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%ACS_Vehicle a flottaszam minimalizalasert fut
[ACSV_fleet, ACSV_TC, ACSV_phermones] = ACS_Vehicle(Initial_fleet, Initial_TC, num_of_cities, distance_matrix, customer_demands, vehicle_cap, load_time, TimeWindow, num_of_ants, beta, gamma, rho, q0);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Global_Best_TC = min(ACSV_TC);
colors = ['r'; 'g'; 'b'; 'c'; 'm'; 'y'; 'k'];
%ACSV eredmenyeinek kirajzolasa
clf reset

Initial_TC_array(1:stopeval) = Initial_TC;
plot(Initial_TC_array, colors(1));
legend_strings{1, 1} = 'CW-Savings';

hold all
%ACSV_TC_array(1:stopeval) = ACSV_TC;
plot(ACSV_TC, '-mo',...
                'LineWidth',2,...
                'MarkerEdgeColor','k',...
                'MarkerFaceColor',colors(2),...
                'MarkerSize',10)
            
legend_strings{1, 2} = 'ACSV';
 
%Addig megy az algoritmus, amig eggyel tobb jarmuvel kevesebb TC-t ki
%tudunk hozni
current_fleet = ACSV_fleet;
i = 2;
    while(1)
         i = i + 1;   
        Global_Best_TC_fleet_inc = ACS_Time(ACSV_phermones, current_fleet, min(ACSV_TC), ...
            stopeval, num_of_cities, distance_matrix, customer_demands, vehicle_cap, load_time, TimeWindow, ...
            num_of_ants, beta, gamma, rho, q0);

        %Az eppeni flottaszammal talalt eredmeny plottolasa
        plot(Global_Best_TC_fleet_inc, '-mo',...
                    'LineWidth',2,...
                    'MarkerEdgeColor','k',...
                    'MarkerFaceColor',colors(i),...
                    'MarkerSize',8)
        legend_strings{1, i} = ['ACST flottameret: ', num2str(current_fleet)];

        %A legkevesebb jarmuvel talalt eredmeny
        if(current_fleet == ACSV_fleet)
        fgbest = sprintf('A min. flottameretre (%d) talalt legrovidebb ut: (%5.1f)', ACSV_fleet, min(Global_Best_TC_fleet_inc));
        end

        %Ha kevesebb lett az osszkoltseg, vagy nem talaltunk megoldast, megpobaljuk + 1 flottaszammal
        if( min(Global_Best_TC_fleet_inc) < Global_Best_TC )
          Global_Best_TC = Global_Best_TC_fleet_inc;
          current_fleet = current_fleet + 1;
        elseif(Global_Best_TC_fleet_inc == Inf)
                current_fleet = current_fleet + 1;
        else
            break; %Egyebkent kilepunk
        end

    end

xlabel('kiértékelési ciklus száma');
axis([1 stopeval min(min(ACSV_TC), min(Global_Best_TC)) max(max(ACSV_TC), max(Global_Best_TC_fleet_inc))])
set(gca,'XTick',1:stopeval)
ylabel('Egy adott kiértékelésben talált teljes útra vonatkozó útköltség');
title('Algoritmusok által talált minimális összköltségek','FontSize',10)
legend(legend_strings);
grid on

disp(fgbest);
