{ inputs, ... }: {
  perSystem = { pkgs, ... }:
    let
      lazygitConfig = (pkgs.formats.yaml {}).generate "lazygit.yml" {
        gui = {
          scrollHeight = 2;
          scrollPastBottom = true;
          scrollOffMargin = 2;
          scrollOffBehavior = "margin";
          mouseEvents = true;
          skipDiscardChangeWarning = false;
          skipStashWarning = false;
          skipNoStagedFilesWarning = false;
          skipRewordInEditorWarning = false;
          sidePanelWidth = 0.3333;
          expandFocusedSidePanel = false;
          expandedSidePanelWeight = 2;
          mainPanelSplitMode = "flexible";
          enlargedSideViewLocation = "left";
          language = "auto";
          timeFormat = "02 Jan 06";
          shortTimeFormat = "3:04PM";
          theme = {
            activeBorderColor = [ "green" "bold" ];
            inactiveBorderColor = [ "default" ];
            searchingActiveBorderColor = [ "cyan" "bold" ];
            optionsTextColor = [ "blue" ];
            selectedLineBgColor = [ "blue" ];
            inactiveViewSelectedLineBgColor = [ "bold" ];
            cherryPickedCommitFgColor = [ "blue" ];
            cherryPickedCommitBgColor = [ "cyan" ];
            markedBaseCommitFgColor = [ "blue" ];
            markedBaseCommitBgColor = [ "yellow" ];
            unstagedChangesColor = [ "red" ];
            defaultFgColor = [ "default" ];
          };
          commitLength = {};
          show = true;
          showListFooter = true;
          showFileTree = true;
          showRandomTip = true;
          showCommandLog = true;
          showBottomLine = true;
          showPanelJumps = true;
          showIcons = false;
          nerdFontsVersion = "3";
          showFileIcons = true;
          commitAuthorShortLength = 2;
          commitAuthorLongLength = 17;
          commitHashLength = 8;
          showBranchCommitHash = false;
          showDivergenceFromBaseBranch = "none";
          commandLogSize = 14;
          splitDiff = "auto";
          screenMode = "normal";
          border = "rounded";
          animateExplosion = true;
          portraitMode = "auto";
          filterMode = "substring";
          spinner = {
            frames = [ "|" "/" "-" "\\" ];
            rate = 50;
          };
          statusPanelView = "dashboard";
          switchToFilesAfterStashPop = true;
          switchToFilesAfterStashApply = true;
          switchTabsWithPanelJumpKeys = false;
        };

        commit = {
          signOff = false;
          autoWrapCommitMessage = true;
          autoWrapWidth = 72;
        };
        merging = {
          manualCommit = false;
          args = "";
          squashMergeMessage = "Squash merge {{selectedRef}} into {{currentBranch}}";
        };
        mainBranches = [ "master" "main" "develop" ];
        skipHookPrefix = "WIP";
        autoFetch = true;
        autoRefresh = true;
        fetchAll = true;
        autoStageResolvedConflicts = true;
        branchLogCmd = "git log --graph --color=always --abbrev-commit --decorate --date=relative --pretty=medium {{branchName}} --";
        overrideGpg = false;
        disableForcePushing = false;
        commitPrefix = [ { pattern = ""; replace = ""; } ];
        branchPrefix = "";
        parseEmoji = false;
        log = {
          order = "topo-order";
          showGraph = "always";
          showWholeGraph = false;
          truncateCopiedCommitHashesTo = 12;
          allBranchesLogCmds = [ "git log --graph --all --color=always --abbrev-commit --decorate --date=relative  --pretty=medium" ];
        };
        update = { method = "never"; days = 14; };
        refresher = { refreshInterval = 10; fetchInterval = 60; };
        confirmOnQuit = false;
        quitOnTopLevelReturn = false;
        os = {
          edit = "nvim {{filename}}";
          editAtLine = "nvim +{{line}} {{filename}}";
          editAtLineAndWait = "nvim +{{line}} {{filename}}";
          openDirInEditor = "nvim .";
          editPreset = "";
          open = "xdg-open {{filename}}";
          openLink = "chromium {{link}}";
          copyToClipboardCmd = "";
          readFromClipboardCmd = "";
        };
        disableStartupPopups = false;
        notARepository = "prompt";
        promptToReturnFromSubprocess = true;

        keybinding = {
          universal = {
            quit = "q"; "quit-alt1" = "<c-c>"; return = "<esc>"; quitWithoutChangingDirectory = "Q"; togglePanel = "<tab>";
            prevItem = "<up>"; nextItem = "<down>"; "prevItem-alt" = "a"; "nextItem-alt" = "h"; prevPage = "'"; nextPage = ".";
            scrollLeft = "Y"; scrollRight = "E"; gotoTop = "<"; gotoBottom = ">"; toggleRangeSelect = "v"; rangeSelectDown = "<s-down>"; rangeSelectUp = "<s-up>";
            prevBlock = "<left>"; nextBlock = "<right>"; "prevBlock-alt" = "y"; "nextBlock-alt" = "e"; "nextBlock-alt2" = "<tab>"; "prevBlock-alt2" = "<backtab>";
            jumpToBlock = [ "1" "2" "3" "4" "5" ]; nextMatch = "n"; prevMatch = "N"; startSearch = "/"; optionMenu = "<f1>"; "optionMenu-alt1" = "?";
            select = "<space>"; goInto = "<enter>"; confirm = "<enter>"; confirmInEditor = "<a-enter>"; remove = "d"; new = "n"; edit = "j"; openFile = "o";
            scrollUpMain = "<pgup>"; scrollDownMain = "<pgdown>"; "scrollUpMain-alt1" = "A"; "scrollDownMain-alt1" = "H"; "scrollUpMain-alt2" = "<c-u>"; "scrollDownMain-alt2" = "<c-d>";
            executeShellCommand = ":"; createRebaseOptionsMenu = "m"; pushFiles = "P"; pullFiles = "p"; refresh = "R"; createPatchOptionsMenu = "<c-p>"; nextTab = "]"; prevTab = "[";
            nextScreenMode = "+"; prevScreenMode = "_"; undo = "z"; redo = "<c-z>"; filteringMenu = "<c-s>"; diffingMenu = "W"; "diffingMenu-alt" = "<c-j>";
            copyToClipboard = "<c-o>"; openRecentRepos = "<c-r>"; submitEditorText = "<enter>"; extrasMenu = "@"; toggleWhitespaceInDiffView = "<c-w>";
            increaseContextInDiffView = "}"; decreaseContextInDiffView = "{"; increaseRenameSimilarityThreshold = ")"; decreaseRenameSimilarityThreshold = "("; openDiffTool = "<c-t>"; newWorktree = "w";
          };
          status = { checkForUpdate = "u"; recentRepos = "<enter>"; allBranchesLogGraph = "k"; };
          files = {
            commitChanges = "c"; commitChangesWithoutHook = "w"; amendLastCommit = "K"; commitChangesWithEditor = "C"; findBaseCommitForFixup = "<c-f>"; confirmDiscard = "x";
            ignoreFile = "i"; refreshFiles = "r"; stashAllChanges = "s"; viewStashOptions = "S"; toggleStagedAll = "k"; viewResetOptions = "D"; fetch = "f"; toggleTreeView = "`"; openMergeOptions = "M"; openStatusFilter = "<c-b>"; copyFileInfoToClipboard = "l";
          };
          branches = { createPullRequest = "o"; viewPullRequestOptions = "O"; copyPullRequestURL = "<c-y>"; checkoutBranchByName = "c"; forceCheckoutBranch = "F"; rebaseBranch = "r"; renameBranch = "R"; mergeIntoCurrentBranch = "M"; viewGitFlowOptions = "i"; fastForward = "f"; createTag = "T"; pushTag = "P"; setUpstream = "u"; fetchRemote = "f"; sortOrder = "s"; };
          commits = { squashDown = "s"; renameCommit = "r"; renameCommitWithEditor = "R"; viewResetOptions = "g"; markCommitAsFixup = "f"; createFixupCommit = "F"; squashAboveCommits = "S"; amendToCommit = "K"; resetCommitAuthor = "k"; pickCommit = "p"; revertCommit = "t"; cherryPickCopy = "C"; pasteCommits = "V"; markCommitAsBaseForRebase = "B"; tagCommit = "T"; checkoutCommit = "<space>"; resetCherryPick = "<c-r>"; copyCommitAttributeToClipboard = "l"; openLogMenu = "<c-l>"; openInBrowser = "o"; viewBisectOptions = "b"; startInteractiveRebase = "i"; };
          amendAttribute = { resetAuthor = "k"; setAuthor = "K"; addCoAuthor = "c"; };
          stash = { popStash = "g"; renameStash = "r"; };
          commitFiles.checkoutCommitFile = "c";
          main = { toggleSelectHunk = "k"; pickBothHunks = "b"; editSelectHunk = "J"; };
          submodules = { init = "i"; update = "u"; bulkMenu = "b"; };
          commitMessage.commitMenu = "<c-o>";
        };

        customCommands = [
          {
            key = "<c-p>";
            context = "files";
            loadingText = "Processing patch";
            command = ''{{if or (eq .Form.patchAction "apply-clip") (eq .Form.patchAction "apply-clip-stat")}}wl-paste | {{end}}git {{if or (eq .Form.patchAction "create") (eq .Form.patchAction "create-clip")}}diff --cached {{if eq .Form.patchAction "create"}}> {{.Form.FileName}}{{else}}| wl-copy{{end}}{{else}}apply {{if or (eq .Form.patchAction "apply-stat") (eq .Form.patchAction "apply-clip-stat")}}--stat{{end}}{{if or (eq .Form.patchAction "apply-stat") (eq .Form.patchAction "apply")}} {{.Form.FileName}}{{end}}{{end}}'';
            output = "log";
            prompts = [
              {
                type = "menu";
                title = "Select patch actions";
                key = "patchAction";
                options = [
                  { name = "Apply patch from file"; value = "apply"; }
                  { name = "Apply patch from clipboard"; value = "apply-clip"; }
                  { name = "Apply patch from file (stats)"; value = "apply-stat"; }
                  { name = "Apply patch from clipboard (stats)"; value = "apply-clip-stat"; }
                  { name = "Create patch-file from staged"; value = "create"; }
                  { name = "Create patch from staged into clipboard"; value = "create-clip"; }
                ];
              }
              {
                type = "input";
                title = "Input file name";
                key = "FileName";
                initialValue = ''{{if or (eq .Form.patchAction "apply") (eq .Form.patchAction "apply-stat")}}~/{{else}}{{if eq .Form.patchAction "create"}}{{.SelectedWorktree.GitDir}}/{{ runCommand "date +\"%s\"" }}.patch{{else}}skip{{end}}{{end}}'';
              }
            ];
          }
        ];
      };
    in {
      packages.lazygit = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.lazygit;
        flags."-ucf" = lazygitConfig;
      };
    };
}
