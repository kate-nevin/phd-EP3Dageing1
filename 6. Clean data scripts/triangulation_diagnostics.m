%% QC Diagnostic Report — 3D Landmark Triangulation
% =========================================================
% Scans all *_3Dlandmarks.csv files under DATA_ROOT and produces:
%   1. A per-file summary CSV      -> qc_summary.csv
%   2. A per-marker summary CSV    -> qc_per_marker.csv
%   3. A multi-page PDF report     -> qc_report.pdf
%
% File naming convention:
%   <participantID>_trial_<NN>_<first|second>_3Dlandmarks.csv
% Columns expected:
%   M0_x, M0_y, M0_z ... M20_x, M20_y, M20_z  (21 markers x 3 axes)
% Frames per video: 240

clc; clear; close all;

%% ── CONFIG ──────────────────────────────────────────────────────────────────
DATA_ROOT    = 'D:\1_EP3Dageing\7. Cleaned data\Raw 3D landmark csv data';
OUTPUT_DIR   = 'D:\1_EP3Dageing\8. Triangulation data check outputs';   % same folder as this script
N_MARKERS    = 21;        % M0 to M20
N_FRAMES     = 240;
NAN_THRESH   = 20;        % % NaN -> "POOR"
NAN_CRITICAL = 50;        % % NaN -> "CRITICAL"
%% ───────────────────────────────────────────────────────────────────────────

% Build expected column names
marker_cols = {};
for m = 0:N_MARKERS-1
    for ax = {'x','y','z'}
        marker_cols{end+1} = sprintf('M%d_%s', m, ax{1}); %#ok<AGROW>
    end
end

%% ── SCAN FILES ──────────────────────────────────────────────────────────────
fprintf('Scanning: %s\n', DATA_ROOT);
file_list = dir(fullfile(DATA_ROOT, '**', '*_3Dlandmarks.csv'));
file_list = [file_list; dir(fullfile(DATA_ROOT, '*_3Dlandmarks.csv'))];

% Remove duplicates
[~, ia] = unique({file_list.name});
file_list = file_list(ia);

if isempty(file_list)
    error('No *_3Dlandmarks.csv files found under %s.\nCheck DATA_ROOT and file naming.', DATA_ROOT);
end
fprintf('Found %d file(s).\n', numel(file_list));

file_re = '^(\d{6})_trial_(\d{2})_(first|second)_3Dlandmarks\.csv$';

% Pre-allocate summary table variables
pid_list      = {};
trial_list    = [];
obj_list      = {};
fname_list    = {};
nframe_list   = [];
nanpct_list   = [];
qual_list     = {};
worstgap_list = [];

% Per-marker storage
mk_pid    = {};
mk_trial  = [];
mk_obj    = {};
mk_marker = [];
mk_nanpct = [];

for fi = 1:numel(file_list)
    fname = file_list(fi).name;
    fpath = fullfile(file_list(fi).folder, fname);

    tok = regexp(fname, file_re, 'tokens', 'ignorecase');
    if isempty(tok)
        fprintf('  [SKIP] Unrecognised filename: %s\n', fname);
        continue
    end

    pid   = tok{1}{1};
    trial = str2double(tok{1}{2});
    obj   = lower(tok{1}{3});

    % Read CSV
    try
        opts = detectImportOptions(fpath, 'VariableNamingRule', 'preserve');
        df   = readtable(fpath, opts);
    catch e
        fprintf('  [ERROR] %s: %s\n', fname, e.message);
        continue
    end

    n_frames = height(df);

    % Find marker columns that exist in this file
    present_cols = intersect(marker_cols, df.Properties.VariableNames, 'stable');
    if isempty(present_cols)
        nan_total = 100;
    else
        data_mat  = table2array(df(:, present_cols));
        nan_total = mean(isnan(data_mat(:))) * 100;
    end

    % Quality label
    if nan_total >= NAN_CRITICAL
        qual = 'CRITICAL';
    elseif nan_total >= NAN_THRESH
        qual = 'POOR';
    else
        qual = 'OK';
    end

    % Longest consecutive NaN run across any column
    worst_run = 0;
    for ci = 1:numel(present_cols)
        col_data = df.(present_cols{ci});
        is_nan   = isnan(col_data);
        if ~any(is_nan), continue; end
        d      = diff([0; double(is_nan); 0]);
        starts = find(d == 1);
        ends   = find(d == -1) - 1;
        runs   = ends - starts + 1;
        worst_run = max(worst_run, max(runs));
    end

    % Store summary row
    pid_list{end+1}      = pid;       %#ok<AGROW>
    trial_list(end+1)    = trial;     %#ok<AGROW>
    obj_list{end+1}      = obj;       %#ok<AGROW>
    fname_list{end+1}    = fname;     %#ok<AGROW>
    nframe_list(end+1)   = n_frames;  %#ok<AGROW>
    nanpct_list(end+1)   = round(nan_total, 2); %#ok<AGROW>
    qual_list{end+1}     = qual;      %#ok<AGROW>
    worstgap_list(end+1) = worst_run; %#ok<AGROW>

    % Per-marker NaN
    for m = 0:N_MARKERS-1
        m_cols = {};
        for ax = {'x','y','z'}
            c = sprintf('M%d_%s', m, ax{1});
            if ismember(c, df.Properties.VariableNames)
                m_cols{end+1} = c; %#ok<AGROW>
            end
        end
        if isempty(m_cols)
            mk_nan = 100;
        else
            md     = table2array(df(:, m_cols));
            mk_nan = round(mean(isnan(md(:))) * 100, 2);
        end
        mk_pid{end+1}    = pid;    %#ok<AGROW>
        mk_trial(end+1)  = trial;  %#ok<AGROW>
        mk_obj{end+1}    = obj;    %#ok<AGROW>
        mk_marker(end+1) = m;      %#ok<AGROW>
        mk_nanpct(end+1) = mk_nan; %#ok<AGROW>
    end
end

%% ── BUILD & SAVE SUMMARY TABLES ─────────────────────────────────────────────
summary_T = table( ...
    pid_list', trial_list', obj_list', fname_list', ...
    nframe_list', nanpct_list', qual_list', worstgap_list', ...
    'VariableNames', {'participant','trial','object','filename', ...
                      'n_frames','nan_pct','quality','worst_consecutive_nan'});
summary_T = sortrows(summary_T, {'participant','trial','object'});

marker_T = table( ...
    mk_pid', mk_trial', mk_obj', mk_marker', mk_nanpct', ...
    'VariableNames', {'participant','trial','object','marker','nan_pct'});

writetable(summary_T, fullfile(OUTPUT_DIR, 'qc_summary.csv'));
writetable(marker_T,  fullfile(OUTPUT_DIR, 'qc_per_marker.csv'));
fprintf('CSVs saved.\n');

%% ── COLOUR HELPERS ──────────────────────────────────────────────────────────
participants = unique(summary_T.participant);
n_parts      = numel(participants);

% Green -> Yellow -> Red colormap (256 steps)
gyr_key = [0.18 0.80 0.46; 0.95 0.76 0.25; 0.91 0.30 0.24];
gyr     = interp1([0 0.5 1], gyr_key, linspace(0,1,256));

C_OK   = [0.18 0.80 0.46];
C_POOR = [0.95 0.76 0.25];
C_CRIT = [0.91 0.30 0.24];
C_HEAD = [0.17 0.24 0.31];

q_cats   = {'OK','POOR','CRITICAL'};
q_colors = {C_OK, C_POOR, C_CRIT};

pdf_path   = fullfile(OUTPUT_DIR, 'qc_report.pdf');
first_page = true;

%% ── PAGE 1: OVERVIEW ─────────────────────────────────────────────────────────
fig1 = figure('Units','inches','Position',[0 0 14 9],'Visible','off');
sgtitle('3D Landmark Triangulation — QC Diagnostic Report', ...
        'FontSize',16,'FontWeight','bold');

% 1a: Quality pie
ax1a = subplot(2,2,1);
q_counts = cellfun(@(q) sum(strcmp(summary_T.quality, q)), q_cats);
non_zero = q_counts > 0;
pie_colors = cell2mat(q_colors(non_zero)');
p = pie(ax1a, q_counts(non_zero));
for k = 1:sum(non_zero)
    p(k*2-1).FaceColor = pie_colors(k,:);
end
legend(ax1a, q_cats(non_zero), 'Location','southoutside','Orientation','horizontal');
title(ax1a, 'File quality breakdown', 'FontWeight','bold');

% 1b: NaN % per participant box plot (no toolbox required)
ax1b = subplot(2,2,2);
bp_data = cellfun(@(p_) summary_T.nan_pct(strcmp(summary_T.participant, p_)), ...
                  participants, 'UniformOutput', false);
hold(ax1b, 'on');
for pi_ = 1:n_parts
    v  = bp_data{pi_};
    v  = v(~isnan(v));
    if isempty(v), continue; end
    q1  = prctile(v, 25);  q3 = prctile(v, 75);
    med = median(v);
    iqr_ = q3 - q1;
    wlo = max(min(v), q1 - 1.5*iqr_);
    whi = min(max(v), q3 + 1.5*iqr_);
    w   = 0.3;
    % Box
    rectangle(ax1b, 'Position',[pi_-w, q1, 2*w, q3-q1], ...
              'FaceColor',[0.20 0.60 0.86], 'EdgeColor','k', 'LineWidth',1.2);
    % Median line
    plot(ax1b, [pi_-w pi_+w], [med med], 'k-', 'LineWidth',2);
    % Whiskers
    plot(ax1b, [pi_ pi_], [wlo q1], 'k-');
    plot(ax1b, [pi_ pi_], [q3 whi], 'k-');
    plot(ax1b, [pi_-w/2 pi_+w/2], [wlo wlo], 'k-');
    plot(ax1b, [pi_-w/2 pi_+w/2], [whi whi], 'k-');
    % Outliers
    out = v(v < wlo | v > whi);
    if ~isempty(out)
        plot(ax1b, repmat(pi_,size(out)), out, 'o', ...
             'MarkerEdgeColor','k', 'MarkerFaceColor','w', 'MarkerSize',4);
    end
end
hold(ax1b, 'off');
yline(ax1b, NAN_THRESH,   '--', 'Color', C_POOR, 'LineWidth',1.5, ...
      'Label', sprintf('Poor (%d%%)', NAN_THRESH));
yline(ax1b, NAN_CRITICAL, '--', 'Color', C_CRIT, 'LineWidth',1.5, ...
      'Label', sprintf('Critical (%d%%)', NAN_CRITICAL));
set(ax1b, 'XTick',1:n_parts, 'XTickLabel',participants, 'XLim',[0.5 n_parts+0.5]);
xlabel(ax1b, 'Participant ID'); ylabel(ax1b, 'NaN %');
title(ax1b, 'NaN % distribution per participant', 'FontWeight','bold');
xtickangle(ax1b, 30);

% 1c: Quality stacked bar per participant
ax1c = subplot(2,2,3);
bar_data = zeros(n_parts, 3);
for pi_ = 1:n_parts
    sub = summary_T(strcmp(summary_T.participant, participants{pi_}), :);
    for qi = 1:3
        bar_data(pi_, qi) = sum(strcmp(sub.quality, q_cats{qi}));
    end
end
b = bar(ax1c, bar_data, 'stacked');
b(1).FaceColor = C_OK;
b(2).FaceColor = C_POOR;
b(3).FaceColor = C_CRIT;
set(ax1c, 'XTickLabel', participants); xtickangle(ax1c, 30);
xlabel(ax1c, 'Participant ID'); ylabel(ax1c, 'Number of files');
title(ax1c, 'File quality counts per participant', 'FontWeight','bold');
legend(ax1c, q_cats, 'Location','northeast');

% 1d: NaN histogram
ax1d = subplot(2,2,4);
histogram(ax1d, summary_T.nan_pct, 20, ...
          'FaceColor',[0.20 0.60 0.86], 'EdgeColor','w');
xline(ax1d, NAN_THRESH,   '--', 'Color', C_POOR, 'LineWidth',1.5, ...
      'Label', sprintf('Poor (%d%%)', NAN_THRESH));
xline(ax1d, NAN_CRITICAL, '--', 'Color', C_CRIT, 'LineWidth',1.5, ...
      'Label', sprintf('Critical (%d%%)', NAN_CRITICAL));
xlabel(ax1d, 'NaN %'); ylabel(ax1d, 'Number of files');
title(ax1d, 'NaN % distribution — all files', 'FontWeight','bold');

exportgraphics(fig1, pdf_path, 'ContentType','vector', 'Append', ~first_page);
first_page = false;
close(fig1);

%% ── PAGE 2: NaN HEATMAP (file x participant) ─────────────────────────────────
n_files = height(summary_T);
fig2    = figure('Units','inches','Position',[0 0 14 max(6, n_files*0.18+2)],'Visible','off');
ax2     = axes(fig2);

heat_mat = NaN(n_files, n_parts);
for pi_ = 1:n_parts
    idx = strcmp(summary_T.participant, participants{pi_});
    heat_mat(idx, pi_) = summary_T.nan_pct(idx);
end
imagesc(ax2, heat_mat);
colormap(ax2, gyr); clim(ax2, [0 100]);
cb2 = colorbar(ax2); cb2.Label.String = 'NaN %';
set(ax2, 'XTick', 1:n_parts, 'XTickLabel', participants, ...
         'YTick', 1:n_files,  'YTickLabel', summary_T.filename, ...
         'FontSize', 6, 'TickLabelInterpreter','none');
xtickangle(ax2, 30);
title(ax2, 'NaN % per file x participant', 'FontWeight','bold', 'FontSize',13);
xlabel(ax2, 'Participant ID');

exportgraphics(fig2, pdf_path, 'ContentType','vector', 'Append', true);
close(fig2);

%% ── PAGE 3: TRIAL x OBJECT heatmaps per participant ─────────────────────────
n_cols_p  = 3;
n_rows_p  = ceil(n_parts / n_cols_p);
fig3 = figure('Units','inches','Position',[0 0 14 n_rows_p*4+1],'Visible','off');
sgtitle('NaN % per trial x object (by participant)', 'FontSize',14,'FontWeight','bold');

trials_all = unique(summary_T.trial);
objs_all   = {'first','second'};

for pi_ = 1:n_parts
    sub = summary_T(strcmp(summary_T.participant, participants{pi_}), :);
    mat = NaN(numel(trials_all), 2);
    for ti = 1:numel(trials_all)
        for oi = 1:2
            r = sub(sub.trial == trials_all(ti) & strcmp(sub.object, objs_all{oi}), :);
            if ~isempty(r), mat(ti, oi) = r.nan_pct(1); end
        end
    end
    ax = subplot(n_rows_p, n_cols_p, pi_);
    imagesc(ax, mat); colormap(ax, gyr); clim(ax, [0 100]);
    colorbar(ax);
    for ti = 1:size(mat,1)
        for oi = 1:size(mat,2)
            if ~isnan(mat(ti,oi))
                text(ax, oi, ti, sprintf('%d', round(mat(ti,oi))), ...
                     'HorizontalAlignment','center','FontSize',6,'Color','k');
            end
        end
    end
    set(ax, 'XTick',1:2,'XTickLabel',objs_all, ...
            'YTick',1:numel(trials_all),'YTickLabel',num2cell(trials_all'),'FontSize',7);
    title(ax, sprintf('Participant %s', participants{pi_}), 'FontWeight','bold');
    xlabel(ax,'Object'); ylabel(ax,'Trial');
end

exportgraphics(fig3, pdf_path, 'ContentType','vector', 'Append', true);
close(fig3);

%% ── PAGE 4: PER-MARKER NaN HEATMAP ──────────────────────────────────────────
fig4 = figure('Units','inches','Position',[0 0 14 8],'Visible','off');
ax4  = axes(fig4);

mk_heat = NaN(N_MARKERS, n_parts);
for pi_ = 1:n_parts
    for m = 0:N_MARKERS-1
        rows_ = marker_T(strcmp(marker_T.participant, participants{pi_}) & marker_T.marker == m, :);
        if ~isempty(rows_)
            mk_heat(m+1, pi_) = mean(rows_.nan_pct);
        end
    end
end
imagesc(ax4, mk_heat);
colormap(ax4, gyr); clim(ax4, [0 100]);
cb4 = colorbar(ax4); cb4.Label.String = 'Mean NaN %';
for m = 1:N_MARKERS
    for pi_ = 1:n_parts
        if ~isnan(mk_heat(m, pi_))
            text(ax4, pi_, m, sprintf('%d', round(mk_heat(m,pi_))), ...
                 'HorizontalAlignment','center','FontSize',8,'Color','k');
        end
    end
end
marker_labels = arrayfun(@(m) sprintf('M%d', m-1), 1:N_MARKERS, 'UniformOutput', false);
set(ax4, 'XTick',1:n_parts,'XTickLabel',participants, ...
         'YTick',1:N_MARKERS,'YTickLabel',marker_labels);
xtickangle(ax4, 30);
title(ax4, 'Mean NaN % per marker x participant (across all trials)', ...
      'FontWeight','bold','FontSize',13);
xlabel(ax4,'Participant ID'); ylabel(ax4,'Marker');

exportgraphics(fig4, pdf_path, 'ContentType','vector', 'Append', true);
close(fig4);

%% ── PAGE 5: WORST CONSECUTIVE NaN GAP ───────────────────────────────────────
fig5 = figure('Units','inches','Position',[0 0 14 5],'Visible','off');
ax5  = axes(fig5);
colors_p = lines(n_parts);
hold(ax5, 'on');
for pi_ = 1:n_parts
    sub = summary_T(strcmp(summary_T.participant, participants{pi_}), :);
    sub = sortrows(sub, {'trial','object'});
    plot(ax5, 1:height(sub), sub.worst_consecutive_nan, ...
         'o-', 'Color', colors_p(pi_,:), 'MarkerSize',4, ...
         'LineWidth',1.2, 'DisplayName', participants{pi_});
end
yline(ax5, N_FRAMES*0.5, '--r', 'LineWidth',1.2, ...
      'Label', sprintf('50%% of frames (%d)', round(N_FRAMES*0.5)));
hold(ax5, 'off');
legend(ax5, 'Location','northeast','NumColumns',3,'FontSize',8);
xlabel(ax5, 'File index (trial x object, sorted)');
ylabel(ax5, 'Longest consecutive NaN run (frames)');
title(ax5, 'Worst consecutive NaN gap per file', 'FontWeight','bold','FontSize',13);

exportgraphics(fig5, pdf_path, 'ContentType','vector', 'Append', true);
close(fig5);

%% ── PAGE 6: POOR/CRITICAL FILE TABLE ────────────────────────────────────────
crit = summary_T(ismember(summary_T.quality, {'POOR','CRITICAL'}), :);
crit = sortrows(crit, 'nan_pct', 'descend');

fig6 = figure('Units','inches','Position',[0 0 14 max(4, height(crit)*0.35+2)],'Visible','off');
ax6  = axes(fig6,'Visible','off');
title(ax6, 'POOR & CRITICAL files (NaN % above threshold)', ...
      'FontWeight','bold','FontSize',13,'Visible','on');
axis(ax6,[0 1 0 1]);

if isempty(crit)
    text(ax6, 0.5, 0.5, 'No POOR or CRITICAL files — all data looks clean!', ...
         'HorizontalAlignment','center','FontSize',14,'Color',C_OK, ...
         'Units','normalized');
else
    col_names = {'Participant','Trial','Object','Frames','NaN %','Longest gap','Quality'};
    n_rows_t  = height(crit);
    n_cols_t  = numel(col_names);
    x_edges   = linspace(0.02, 0.98, n_cols_t+1);
    y_edges   = linspace(0.95, 0.05, n_rows_t+2);

    % Header row
    for ci = 1:n_cols_t
        x0 = x_edges(ci); x1 = x_edges(ci+1);
        y0 = y_edges(2);  y1 = y_edges(1);
 % REPLACE with:
fill(ax6, [x0 x1 x1 x0], [y0 y0 y1 y1], C_HEAD, 'EdgeColor','w');
        text(ax6,(x0+x1)/2,(y0+y1)/2, col_names{ci}, ...
             'HorizontalAlignment','center','FontWeight','bold', ...
             'FontSize',8,'Color','w','Units','normalized');
    end

    % Data rows
    for ri = 1:n_rows_t
        q_ri  = crit.quality{ri};
        row_c = [1 0.94 0.94];   % light red for CRITICAL
        if strcmp(q_ri,'POOR'), row_c = [1 0.98 0.88]; end  % light yellow for POOR

        row_vals = {crit.participant{ri}, ...
                    num2str(crit.trial(ri)), ...
                    crit.object{ri}, ...
                    num2str(crit.n_frames(ri)), ...
                    sprintf('%.1f', crit.nan_pct(ri)), ...
                    num2str(crit.worst_consecutive_nan(ri)), ...
                    crit.quality{ri}};
        for ci = 1:n_cols_t
            x0 = x_edges(ci);   x1 = x_edges(ci+1);
            y0 = y_edges(ri+2); y1 = y_edges(ri+1);
            fill(ax6, [x0 x1 x1 x0], [y0 y0 y1 y1], row_c, 'EdgeColor',[0.8 0.8 0.8]);
        end
    end
end

exportgraphics(fig6, pdf_path, 'ContentType','vector', 'Append', true);
close(fig6);

%% ── DONE ─────────────────────────────────────────────────────────────────────
fprintf('\nDone! Outputs written to: %s\n', OUTPUT_DIR);
fprintf('  qc_summary.csv      -- one row per file\n');
fprintf('  qc_per_marker.csv   -- one row per file x marker\n');
fprintf('  qc_report.pdf       -- 6-page visual report\n');

%% Functions

function c = qcolor(q, C_OK, C_POOR, C_CRIT)
    switch q
        case 'OK';       c = C_OK;
        case 'POOR';     c = C_POOR;
        case 'CRITICAL'; c = C_CRIT;
        otherwise;       c = [0.5 0.5 0.5];
    end
end