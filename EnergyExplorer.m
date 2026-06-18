function EnergyExplorer()
% EnergyExplorer — Interactive Malaysian Electricity Generation Dashboard
% Data source: OpenDOSM (Department of Statistics Malaysia)
% Covers 2000–2023 electricity generation by fuel type (GWh)
%
% Run this file in MATLAB R2020b or later.

    %% ── Load Data ────────────────────────────────────────────────────────
    scriptDir = fileparts(mfilename('fullpath'));
    csvPath   = fullfile(scriptDir, 'malaysia_electricity_generation.csv');
    T = readtable(csvPath);

    energySources = {'Coal_GWh','NaturalGas_GWh','Hydro_GWh','Solar_GWh','OtherRenewable_GWh'};
    sourceLabels  = {'Coal','Natural Gas','Hydro','Solar','Other Renewable'};
    sourceColors  = {'#c0392b','#e67e22','#2980b9','#f1c40f','#27ae60'};

    %% ── Figure & Layout ──────────────────────────────────────────────────
    fig = uifigure('Name','Malaysia Electricity Generation Explorer', ...
                   'Position',[100 80 1100 680], ...
                   'Color','#1a1a2e');

    % Left panel – controls
    leftPanel = uipanel(fig,'Position',[10 10 240 660], ...
                        'BackgroundColor','#16213e','BorderType','none');

    % Right panel – charts
    rightPanel = uipanel(fig,'Position',[260 10 830 660], ...
                         'BackgroundColor','#1a1a2e','BorderType','none');

    %% ── Title ────────────────────────────────────────────────────────────
    uilabel(leftPanel,'Text','⚡ Energy Explorer', ...
            'Position',[10 620 220 30],'FontSize',16,'FontWeight','bold', ...
            'FontColor','#00d4ff','BackgroundColor','#16213e');

    uilabel(leftPanel,'Text','Malaysia · OpenDOSM Data', ...
            'Position',[10 598 220 22],'FontSize',10, ...
            'FontColor','#7f8c8d','BackgroundColor','#16213e');

    %% ── Dropdown: energy source ─────────────────────────────────────────
    uilabel(leftPanel,'Text','Energy Source', ...
            'Position',[10 565 220 20],'FontColor','#ecf0f1', ...
            'BackgroundColor','#16213e','FontWeight','bold');

    ddSource = uidropdown(leftPanel, ...
        'Items',['All Sources', sourceLabels], ...
        'Position',[10 540 220 25], ...
        'BackgroundColor','#0f3460','FontColor','#ecf0f1', ...
        'ValueChangedFcn',@(~,~) refreshPlot());

    %% ── Dropdown: chart type ─────────────────────────────────────────────
    uilabel(leftPanel,'Text','Chart Type', ...
            'Position',[10 510 220 20],'FontColor','#ecf0f1', ...
            'BackgroundColor','#16213e','FontWeight','bold');

    ddChart = uidropdown(leftPanel, ...
        'Items',{'Line Chart','Bar Chart','Stacked Area','Pie (Latest Year)'}, ...
        'Position',[10 485 220 25], ...
        'BackgroundColor','#0f3460','FontColor','#ecf0f1', ...
        'ValueChangedFcn',@(~,~) refreshPlot());

    %% ── Slider: year range ───────────────────────────────────────────────
    uilabel(leftPanel,'Text','Start Year', ...
            'Position',[10 455 220 20],'FontColor','#ecf0f1', ...
            'BackgroundColor','#16213e','FontWeight','bold');

    sliderStart = uislider(leftPanel, ...
        'Limits',[2000 2023],'Value',2000,'MajorTicks',2000:5:2023, ...
        'Position',[10 435 210 3], ...
        'FontColor','#ecf0f1', ...
        'ValueChangedFcn',@(~,~) onSliderChange());

    lblStartVal = uilabel(leftPanel,'Text','2000', ...
        'Position',[10 415 100 20],'FontColor','#00d4ff', ...
        'BackgroundColor','#16213e','FontWeight','bold');

    uilabel(leftPanel,'Text','End Year', ...
            'Position',[10 390 220 20],'FontColor','#ecf0f1', ...
            'BackgroundColor','#16213e','FontWeight','bold');

    sliderEnd = uislider(leftPanel, ...
        'Limits',[2000 2023],'Value',2023,'MajorTicks',2000:5:2023, ...
        'Position',[10 370 210 3], ...
        'FontColor','#ecf0f1', ...
        'ValueChangedFcn',@(~,~) onSliderChange());

    lblEndVal = uilabel(leftPanel,'Text','2023', ...
        'Position',[10 350 100 20],'FontColor','#00d4ff', ...
        'BackgroundColor','#16213e','FontWeight','bold');

    %% ── Status Lamp ──────────────────────────────────────────────────────
    uilabel(leftPanel,'Text','Renewables Status', ...
            'Position',[10 315 220 20],'FontColor','#ecf0f1', ...
            'BackgroundColor','#16213e','FontWeight','bold');

    lamp = uilamp(leftPanel,'Position',[10 285 25 25],'Color','red');

    lblLamp = uilabel(leftPanel,'Text','< 10% renewable share', ...
            'Position',[42 285 185 25],'FontColor','#e74c3c', ...
            'BackgroundColor','#16213e','FontSize',9);

    uilabel(leftPanel,'Text','● <10%: Red  ● 10–20%: Amber  ● >20%: Green', ...
            'Position',[10 262 220 20],'FontColor','#7f8c8d', ...
            'BackgroundColor','#16213e','FontSize',8);

    %% ── Statistics Panel ─────────────────────────────────────────────────
    uilabel(leftPanel,'Text','Statistics', ...
            'Position',[10 235 220 20],'FontColor','#ecf0f1', ...
            'BackgroundColor','#16213e','FontWeight','bold');

    txtStats = uitextarea(leftPanel, ...
        'Position',[10 130 220 105], ...
        'BackgroundColor','#0f3460','FontColor','#00d4ff', ...
        'Editable','off','FontSize',9, ...
        'Value',{'Click "Statistical Analysis"','to compute metrics.'});

    btnStats = uibutton(leftPanel,'push', ...
        'Text','📊 Statistical Analysis', ...
        'Position',[10 98 220 30], ...
        'BackgroundColor','#533483','FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~) runStats());

    %% ── Export Buttons ───────────────────────────────────────────────────
    btnExportCSV = uibutton(leftPanel,'push', ...
        'Text','💾 Export Filtered CSV', ...
        'Position',[10 60 220 30], ...
        'BackgroundColor','#1a6b3c','FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~) exportCSV());

    btnSaveImg = uibutton(leftPanel,'push', ...
        'Text','🖼 Save Chart as PNG', ...
        'Position',[10 22 220 30], ...
        'BackgroundColor','#1a5276','FontColor','white','FontWeight','bold', ...
        'ButtonPushedFcn',@(~,~) saveImage());

    %% ── Axes ─────────────────────────────────────────────────────────────
    ax = uiaxes(rightPanel,'Position',[30 80 770 540], ...
                'Color','#0d1117','XColor','#ecf0f1','YColor','#ecf0f1', ...
                'GridColor','#2c3e50','GridAlpha',0.5,'Box','on');
    ax.Title.Color  = '#ecf0f1';
    ax.XLabel.Color = '#ecf0f1';
    ax.YLabel.Color = '#ecf0f1';
    grid(ax,'on');

    %% ── Initial Draw ─────────────────────────────────────────────────────
    refreshPlot();

    %% ══════════════════════════════════════════════════════════════════════
    %  NESTED HELPER FUNCTIONS
    %% ══════════════════════════════════════════════════════════════════════

    function filtT = getFiltered()
        y1 = round(sliderStart.Value);
        y2 = round(sliderEnd.Value);
        if y1 > y2, y1 = y2; end
        filtT = T(T.Year >= y1 & T.Year <= y2, :);
    end

    function onSliderChange()
        lblStartVal.Text = sprintf('%d', round(sliderStart.Value));
        lblEndVal.Text   = sprintf('%d', round(sliderEnd.Value));
        refreshPlot();
    end

    function refreshPlot()
        filtT = getFiltered();
        cla(ax);
        hold(ax,'on');

        chartType = ddChart.Value;
        src       = ddSource.Value;

        if strcmp(chartType,'Pie (Latest Year)')
            % Pie of the latest year in filtered range
            latestRow = filtT(end,:);
            vals = zeros(1,numel(energySources));
            for k = 1:numel(energySources)
                vals(k) = latestRow.(energySources{k});
            end
            pie(ax, vals, sourceLabels);
            title(ax, sprintf('Generation Mix — %d', latestRow.Year), ...
                  'FontSize',13,'FontWeight','bold');
            hold(ax,'off');
            updateLamp(filtT);
            return
        end

        % Determine which columns to plot
        if strcmp(src,'All Sources')
            cols  = energySources;
            clbls = sourceLabels;
            clrs  = sourceColors;
        else
            idx   = strcmp(sourceLabels, src);
            cols  = energySources(idx);
            clbls = sourceLabels(idx);
            clrs  = sourceColors(idx);
        end

        years = filtT.Year;

        switch chartType
            case 'Line Chart'
                for k = 1:numel(cols)
                    plot(ax, years, filtT.(cols{k}), '-o', ...
                         'Color', clrs{k}, 'LineWidth',2, ...
                         'MarkerFaceColor', clrs{k}, 'MarkerSize',5, ...
                         'DisplayName', clbls{k});
                end
                legend(ax,'Location','northwest','TextColor','#ecf0f1', ...
                       'Color','#16213e','EdgeColor','#2c3e50');
                xlabel(ax,'Year'); ylabel(ax,'Generation (GWh)');
                title(ax,'Electricity Generation by Source (GWh)','FontSize',13,'FontWeight','bold');

            case 'Bar Chart'
                data = zeros(height(filtT), numel(cols));
                for k = 1:numel(cols)
                    data(:,k) = filtT.(cols{k});
                end
                b = bar(ax, years, data, 'grouped');
                for k = 1:numel(b)
                    b(k).FaceColor = clrs{k};
                    b(k).DisplayName = clbls{k};
                end
                legend(ax,'Location','northwest','TextColor','#ecf0f1', ...
                       'Color','#16213e','EdgeColor','#2c3e50');
                xlabel(ax,'Year'); ylabel(ax,'Generation (GWh)');
                title(ax,'Electricity Generation by Source (GWh)','FontSize',13,'FontWeight','bold');

            case 'Stacked Area'
                data = zeros(height(filtT), numel(cols));
                for k = 1:numel(cols)
                    data(:,k) = filtT.(cols{k});
                end
                ar = area(ax, years, data);
                for k = 1:numel(ar)
                    ar(k).FaceColor = clrs{k};
                    ar(k).FaceAlpha = 0.8;
                    ar(k).EdgeColor = 'none';
                    ar(k).DisplayName = clbls{k};
                end
                legend(ax,'Location','northwest','TextColor','#ecf0f1', ...
                       'Color','#16213e','EdgeColor','#2c3e50');
                xlabel(ax,'Year'); ylabel(ax,'Generation (GWh)');
                title(ax,'Stacked Area — Electricity Generation (GWh)','FontSize',13,'FontWeight','bold');
        end

        hold(ax,'off');
        updateLamp(filtT);
    end

    function updateLamp(filtT)
        % Renewables = Hydro + Solar + Other
        renewGWh = filtT.Hydro_GWh + filtT.Solar_GWh + filtT.OtherRenewable_GWh;
        pct = 100 * mean(renewGWh) / mean(filtT.Total_GWh);
        if pct >= 20
            lamp.Color = '#27ae60';  % green
            lblLamp.Text = sprintf('%.1f%% renewable — Good', pct);
            lblLamp.FontColor = '#27ae60';
        elseif pct >= 10
            lamp.Color = '#f39c12';  % amber
            lblLamp.Text = sprintf('%.1f%% renewable — Moderate', pct);
            lblLamp.FontColor = '#f39c12';
        else
            lamp.Color = '#e74c3c';  % red
            lblLamp.Text = sprintf('%.1f%% renewable — Low', pct);
            lblLamp.FontColor = '#e74c3c';
        end
    end

    function runStats()
        filtT = getFiltered();
        src   = ddSource.Value;

        if strcmp(src,'All Sources')
            col = 'Total_GWh';
            lbl = 'Total';
        else
            idx = strcmp(sourceLabels, src);
            col = energySources{idx};
            lbl = src;
        end

        vals = filtT.(col);
        mu   = mean(vals);
        sd   = std(vals);
        mn   = min(vals);
        mx   = max(vals);
        CAGR = 100*((vals(end)/vals(1))^(1/(numel(vals)-1)) - 1);

        renewGWh = filtT.Hydro_GWh + filtT.Solar_GWh + filtT.OtherRenewable_GWh;
        avgRenew = 100 * mean(renewGWh) / mean(filtT.Total_GWh);

        txtStats.Value = {
            sprintf('Source : %s', lbl)
            sprintf('Mean   : %,.0f GWh', mu)
            sprintf('Std Dev: %,.0f GWh', sd)
            sprintf('Min    : %,.0f GWh', mn)
            sprintf('Max    : %,.0f GWh', mx)
            sprintf('CAGR   : %.2f %%/yr', CAGR)
            sprintf('Avg RE%%: %.1f %%', avgRenew)
        };
    end

    function exportCSV()
        filtT = getFiltered();
        y1 = round(sliderStart.Value);
        y2 = round(sliderEnd.Value);
        defaultName = sprintf('MY_Energy_%d_%d.csv', y1, y2);
        [fname, fpath] = uiputfile('*.csv','Save Filtered Data As', defaultName);
        if isequal(fname,0), return; end
        writetable(filtT, fullfile(fpath,fname));
        uialert(fig, sprintf('Saved: %s', fullfile(fpath,fname)), ...
                'Export Successful','Icon','success');
    end

    function saveImage()
        y1 = round(sliderStart.Value);
        y2 = round(sliderEnd.Value);
        defaultName = sprintf('MY_Energy_Chart_%d_%d.png', y1, y2);
        [fname, fpath] = uiputfile('*.png','Save Chart As', defaultName);
        if isequal(fname,0), return; end
        exportgraphics(ax, fullfile(fpath,fname), 'Resolution',300);
        uialert(fig, sprintf('Saved: %s', fullfile(fpath,fname)), ...
                'Image Saved','Icon','success');
    end

end
