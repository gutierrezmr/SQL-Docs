create table z_mgutierrez.pinpoint as
(
 SELECT ally_invest_pinpoint.session.session_id  as "session_id",
            ally_invest_pinpoint.session.start_timestamp as "session_start",
            ally_invest_pinpoint.session.stop_timestamp  as "session_stop",
            user_allyguid,
            user_sviuserid,
            user_username,
            user_email,
            user_isprofessionaluser,
            user_istradingdisabled,
            ally_invest_pinpoint.device.make  as "device_make",
            ally_invest_pinpoint.device.model  as "device_model",
            ally_invest_pinpoint.device.platform.name  as "device_platform_name",
            ally_invest_pinpoint.attributes.buttonid  as "button_id",
            ally_invest_pinpoint.attributes.url  as "url",
            --ally_invest_pinpoint.attributes.campaign_id  as "campaign_id",
            --ally_invest_pinpoint.attributes.campaign_activity_id  as "campaign_activity_id",
            ally_invest_pinpoint.event_timestamp as "event_timestamp",
            ally_invest_pinpoint.arrival_timestamp as "arrival_timestamp",
            ally_invest_pinpoint.application.version_name  as "application_version_name",
            ally_invest_pinpoint.event_type  as "event_type",
            ally_invest_pinpoint.event_version  as "event_version",
            ally_invest_pinpoint.application.app_id  as "application_id",
            ally_invest_pinpoint.partition_0  as "partition_year",
            ally_invest_pinpoint.partition_1  as "partition_month",
            ally_invest_pinpoint.partition_2  as "partition_day",
            ally_invest_pinpoint.partition_3  as "partition_hour"
          FROM pinpoint.ally_invest_531126081042_pinpoint  as ally_invest_pinpoint,
            ally_invest_pinpoint.endpoint.user.userattributes.isprofessionaluser  as user_isprofessionaluser,
            ally_invest_pinpoint.endpoint.user.userattributes.istradingdisabled  as user_istradingdisabled,
            ally_invest_pinpoint.endpoint.user.userattributes.sviUserId  as user_sviuserid,
            ally_invest_pinpoint.endpoint.user.userattributes.username  as user_username,
            ally_invest_pinpoint.endpoint.user.userattributes.email  as user_email,
            ally_invest_pinpoint.endpoint.user.userattributes.allyguid  as user_allyguid
            );
            
SELECT * from z_mgutierrez.pinpoint where url LIKE '%tools%' limit 10;
 
SELECT count (DISTINCT user_username), partition_year, partition_month From z_mgutierrez.pinpoint where url
in ('https://live.invest.ally.com/trading-full/stocks','https://live.invest.ally.com/trading-full/options', 'https://live.invest.ally.com/trading-full/mutual-funds',
'https://live.invest.ally.com/trading-full/fixed-income', 'https://live.invest.ally.com/trading-full/order-status')and partition_year > 2019 group by 2,3
order by partition_year asc, partition_month asc;
 
 
 
 
SELECT count (DISTINCT user_username), partition_year, partition_month From z_mgutierrez.pinpoint where button_id LIKE '%QuickTrade%' and partition_year > 2019 group by 2,3
order by partition_year asc, partition_month asc;
 
