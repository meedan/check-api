# Load classes on boot, in production, that otherwise wouldn't be auto-loaded by default
CcDeville && Bot::Keep && Workflow::Workflow.workflows && CheckS3 && Bot::Tagger && Bot::Fetch && Bot::Smooch && Bot::Slack && Bot::Alegre && CheckChannels && RssFeed && UrlRewriter && ClusterTeam && ListExport && TeamStatistics && CheckDataPoints && CheckMediaClusterOrigins
