library(haven)
library(dplyr)
library(ggplot2)
library(scales)

df <- read.csv("~/Downloads/output_gender_masked.csv")
names(df)

df <- df %>%
  mutate(BT = sub("BT_(\\d{2})_.*", "BT\\1", source_file))

gov_map <- list(
  BT02 = c("CDU","CSU","FDP"),
  BT03 = c("CDU","CSU"),
  BT04 = c("CDU","CSU","FDP"),
  BT05 = c("CDU","CSU","SPD"),
  BT06 = c("SPD","FDP"),
  BT07 = c("SPD","FDP"),
  BT08 = c("SPD","FDP"),
  BT09 = c("CDU","CSU","FDP"),
  BT10 = c("CDU","CSU","FDP"),
  BT11 = c("CDU","CSU","FDP"),
  BT12 = c("CDU","CSU","FDP"),
  BT13 = c("CDU","CSU","FDP"),
  BT14 = c("SPD","GRUENE"),
  BT15 = c("SPD","GRUENE"),
  BT16 = c("CDU","CSU","SPD"),
  BT17 = c("CDU","CSU","FDP"),
  BT18 = c("CDU","CSU","SPD"),
  BT19 = c("CDU","CSU","SPD")
)

is_gov <- function(bt, party) {
  party %in% gov_map[[bt]]
}

df <- df %>%
  mutate(
    current_gov = mapply(is_gov, BT, current_party) * 1,
    interruptor_gov = mapply(is_gov, BT, interruptor_party) * 1
  )

female_bt <- data.frame(
  BT = paste0("BT", sprintf("%02d", 2:19)),
  female_share_bt = c(
    0.068, 0.058, 0.069, 0.067, 0.058, 0.077, 0.084, 0.098,
    0.145, 0.154, 0.205, 0.262, 0.309, 0.322, 0.316, 0.328,
    0.365, 0.309
  )
)

df <- df %>%
  left_join(female_bt, by = "BT")

current_gender_bt <- df %>%
  group_by(BT) %>%
  summarise(
    share_current_gender = mean(current_gender == "female", na.rm = TRUE),
    .groups = "drop"
  )

interruptor_gender_bt <- df %>%
  group_by(BT) %>%
  summarise(
    share_interruptor_gender = mean(interruptor_gender == "female", na.rm = TRUE),
    .groups = "drop"
  )


current_gov_bt <- df %>%
  group_by(BT) %>%
  summarise(
    share_current_gov = mean(current_gov == 1, na.rm = TRUE),
    .groups = "drop"
  )

interruptor_gov_bt <- df %>%
  group_by(BT) %>%
  summarise(
    share_interruptor_gov = mean(interruptor_gov == 1, na.rm = TRUE),
    .groups = "drop"
  )

df <- df %>%
  left_join(current_gender_bt, by = "BT") %>%
  left_join(interruptor_gender_bt, by = "BT") %>%
  left_join(current_gov_bt, by = "BT") %>%
  left_join(interruptor_gov_bt, by = "BT")

## histograms

df %>%
  count(BT, current_gov) %>%
  ggplot(aes(x = BT, y = n, fill = factor(current_gov))) +
  geom_col() +
  theme_minimal() +
  labs(
    x = "Bundestag",
    y = "Number of interruptions received",
    fill = "Government status"
  ) +
  scale_fill_manual(
    labels = c("Opposition", "Government"),
    values = c("orange", "black")
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0, 1),
    legend.justification = c(0, 1)
  )

df %>%
  count(BT, interruptor_gov) %>%
  ggplot(aes(x = BT, y = n, fill = factor(interruptor_gov))) +
  geom_col() +
  theme_minimal() +
  labs(
    x = "Bundestag",
    y = "Number of interruptions made",
    fill = "Government status"
  ) +
  scale_fill_manual(
    labels = c("Opposition", "Government"),
    values = c("orange", "black")
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0, 1),
    legend.justification = c(0, 1)
  )

df %>%
  count(BT, current_gender) %>%
  ggplot(aes(x = BT, y = n, fill = factor(current_gender))) +
  geom_col() +
  theme_minimal() +
  labs(
    x = "Bundestag",
    y = "Number of interruptions received",
    fill = "Gender"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

df %>%
  count(BT, interruptor_gender) %>%
  ggplot(aes(x = BT, y = n, fill = factor(interruptor_gender))) +
  geom_col() +
  theme_minimal() +
  labs(
    x = "Bundestag",
    y = "Number of interruptions made",
    fill = "Gender"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

df %>%
  group_by(BT) %>%
  summarise(
    share_current_gender = mean(share_current_gender, na.rm = TRUE),
    female_share_bt = mean(female_share_bt, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = BT)) +
  geom_col(
    aes(y = share_current_gender, fill = "Interrupted"),
    width = 0.4,
    position = position_nudge(x = -0.2)
  ) +
  geom_col(
    aes(y = female_share_bt, fill = "Seats in the Bundestag"),
    width = 0.4,
    position = position_nudge(x = 0.2)
  ) +
  scale_fill_manual(
    values = c(
      "Interrupted" = "darkblue",
      "Seats in the Bundestag" = "lightblue"
    )
  ) +
  theme_minimal() +
  labs(
    x = "Bundestag",
    y = "Female share",
    fill = NULL
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0, 1),    
    legend.justification = c(0, 1)
  )

df %>%
  group_by(BT) %>%
  summarise(
    share_interruptor_gender = mean(share_interruptor_gender, na.rm = TRUE),
    female_share_bt = mean(female_share_bt, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = BT)) +
  geom_col(
    aes(y = share_interruptor_gender, fill = "Interruptor"),
    width = 0.4,
    position = position_nudge(x = -0.2)
  ) +
  geom_col(
    aes(y = female_share_bt, fill = "Seats in the Bundestag"),
    width = 0.4,
    position = position_nudge(x = 0.2)
  ) +
  scale_fill_manual(
    values = c(
      "Interruptor" = "blue2",
      "Seats in the Bundestag" = "lightblue"
    )
  ) +
  theme_minimal() +
  labs(
    x = "Bundestag",
    y = "Female share",
    fill = NULL
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.position = c(0, 1),    
    legend.justification = c(0, 1)
  )

df %>%
  filter(
    current_gender != "no lookup",
    interruptor_gender != "no lookup"
  ) %>%
  count(interruptor_gender, current_gender) %>%
  ggplot(aes(x = current_gender, y = interruptor_gender, fill = n)) +
  geom_tile(color = "white") +
  geom_text(aes(label = n), size = 5) +
  theme_minimal() +
  labs(
    x = "Interrupted gender",
    y = "Interruptor gender",
    fill = "Count"
  ) +
  scale_x_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_y_discrete(labels = c("female" = "Female", "male" = "Male"))

df %>%
  filter(
    current_gender != "no lookup",
    interruptor_gender != "no lookup"
  ) %>%
  count(interruptor_gender, current_gender) %>%
  group_by(interruptor_gender) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  ggplot(aes(x = current_gender, y = interruptor_gender, fill = share)) +
  geom_tile(color = "white") +
  geom_text(aes(label = percent(share, accuracy = 0.1)), size = 5) +
  theme_minimal() +
  labs(
    x = "Interrupted gender",
    y = "Interruptor gender",
    fill = "Row share"
  ) +
  scale_x_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_y_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_fill_gradient(labels = percent_format(accuracy = 1))

range_vals <- df %>%
  filter(
    current_gender != "no lookup",
    interruptor_gender != "no lookup"
  ) %>%
  count(interruptor_gender, current_gender) %>%
  group_by(interruptor_gender) %>%
  mutate(row_share = n / sum(n)) %>%
  ungroup() %>%
  mutate(total_n = sum(n)) %>%
  group_by(current_gender) %>%
  mutate(overall_share = sum(n) / first(total_n)) %>%
  ungroup() %>%
  mutate(ratio = row_share / overall_share) %>%
  summarise(min = min(ratio), max = max(ratio))

df %>%
  filter(
    current_gender != "no lookup",
    interruptor_gender != "no lookup"
  ) %>%
  count(interruptor_gender, current_gender) %>%
  group_by(interruptor_gender) %>%
  mutate(row_share = n / sum(n)) %>%
  ungroup() %>%
  mutate(total_n = sum(n)) %>%
  group_by(current_gender) %>%
  mutate(overall_share = sum(n) / first(total_n)) %>%
  ungroup() %>%
  mutate(ratio = row_share / overall_share) %>%
  ggplot(aes(x = current_gender, y = interruptor_gender, fill = ratio)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(ratio, 2)), size = 5) +
  theme_minimal() +
  labs(
    x = "Interrupted gender",
    y = "Interruptor gender"
  ) +
  scale_x_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_y_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_fill_gradient2(
    low = "white",
    mid = "#deebf7",
    high = "#08519c",
    midpoint = 1,
    limits = c(range_vals$min, range_vals$max)
  ) +
  theme(
    legend.position = "none"
  )

df %>%
  filter(
    BT %in% c("BT16", "BT17", "BT18", "BT19"),
    current_gender != "no lookup",
    interruptor_gender != "no lookup"
  ) %>%
  count(interruptor_gender, current_gender) %>%
  group_by(interruptor_gender) %>%
  mutate(row_share = n / sum(n)) %>%
  ungroup() %>%
  mutate(total_n = sum(n)) %>%
  group_by(current_gender) %>%
  mutate(overall_share = sum(n) / first(total_n)) %>%
  ungroup() %>%
  mutate(ratio = row_share / overall_share) %>%
  ggplot(aes(x = current_gender, y = interruptor_gender, fill = ratio)) +
  geom_tile(color = "white") +
  geom_text(aes(label = round(ratio, 2)), size = 5) +
  theme_minimal() +
  labs(
    x = "Interrupted gender",
    y = "Interruptor gender"
  ) +
  scale_x_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_y_discrete(labels = c("female" = "Female", "male" = "Male")) +
  scale_fill_gradient2(
    low = "white",
    mid = "#deebf7",
    high = "#08519c",
    midpoint = 1,
    limits = c(range_vals$min, range_vals$max)
  ) +
  theme(
    legend.position = "none"
  )

df_plot <- df %>%
  mutate(
    granted = ifelse(permission_granted == "True", "Granted", "Not granted"),
    granted_binary = ifelse(permission_granted == "True", 1, 0)
  )

df_plot <- df_plot %>%
  mutate(
    BT = factor(BT, levels = sort(unique(BT)))
  )

plot_bt <- df_plot %>%
  group_by(BT) %>%
  summarise(
    share_granted = mean(granted_binary, na.rm = TRUE),
    n = n(),
    .groups = "drop"
  ) %>%
  ggplot(aes(x = BT, y = share_granted, group = 1)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Bundestag",
    y = "Share of granted parliamentary questions"
    ) +
  theme_minimal()

plot_bt


plot_gender_stacked <- df_plot %>%
  filter(
    !is.na(current_gender),
    current_gender != "no lookup",
    !is.na(granted)
  ) %>%
  mutate(
    target_gender = recode(current_gender,
                           "male" = "Male",
                           "female" = "Female"),
    target_gender = factor(target_gender, levels = c("Male", "Female")),
    granted = factor(granted, levels = c("Not granted", "Granted"))
  ) %>%
  ggplot(aes(x = target_gender, fill = granted)) +
  geom_bar(position = "fill") +
  scale_fill_manual(
    values = c("Not granted" = "#d73027",  # rot
               "Granted" = "#1a9850")      # grün
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Gender of addressed speaker",
    y = "Share",
    fill = "Permission"
    ) +
  theme_minimal()

plot_gender_stacked

plot_gender_stacked_2 <- df_plot %>%
  filter(
    !is.na(interruptor_gender),
    interruptor_gender != "no lookup",
    !is.na(granted)
  ) %>%
  mutate(
    interruptor_gender = recode(interruptor_gender,
                                "male" = "Male",
                                "female" = "Female"),
    interruptor_gender = factor(interruptor_gender, levels = c("Male", "Female")),
    granted = factor(granted, levels = c("Not granted", "Granted"))
  ) %>%
  ggplot(aes(x = interruptor_gender, fill = granted)) +
  geom_bar(position = "fill") +
  scale_fill_manual(
    values = c("Not granted" = "#d73027",
               "Granted" = "#1a9850")
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Gender of interruptor",
    y = "Share",
    fill = "Permission"
  ) +
  theme_minimal()

plot_gender_stacked_2

party_colors <- c(
  "SPD" = "#E3000F",
  "AfD" = "#009EE0",
  "FDP" = "#FFED00",
  "CDU/CSU" = "#000000",
  "DIE LINKE" = "#BE3075",
  "GRUENE" = "#64A12D"
)

plot_bt19_permission_by_party <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    !is.na(permission_granted)
  ) %>%
  mutate(
    party = current_parliamentary_group,
    granted = case_when(
      permission_granted == "True" ~ "Granted",
      permission_granted == "" ~ "Not granted",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(granted)) %>%
  group_by(party) %>%
  mutate(granted_share = mean(granted == "Granted")) %>%
  ungroup() %>%
  mutate(
    party = reorder(party, -granted_share),
    granted = factor(granted, levels = c("Not granted", "Granted"))
  ) %>%
  ggplot(aes(x = party, fill = granted)) +
  geom_bar(position = "fill") +
  scale_fill_manual(
    values = c("Not granted" = "#d73027",
               "Granted" = "#1a9850")
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Parliamentary group (addressed speaker)",
    y = "Share",
    fill = "Permission"
  ) +
  theme_minimal()

plot_bt19_permission_by_party

plot_bt19_permission_by_interruptor_party <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    party = interruptor_parliamentary_group,
    granted = case_when(
      permission_granted == "True" ~ "Granted",
      permission_granted == "" ~ "Not granted",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(granted)) %>%
  group_by(party) %>%
  mutate(granted_share = mean(granted == "Granted")) %>%
  ungroup() %>%
  mutate(
    party = reorder(party, -granted_share),
    granted = factor(granted, levels = c("Not granted", "Granted"))
  ) %>%
  ggplot(aes(x = party, fill = granted)) +
  geom_bar(position = "fill") +
  scale_fill_manual(
    values = c("Not granted" = "#d73027",
               "Granted" = "#1a9850")
  ) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(
    x = "Parliamentary group (interruptor)",
    y = "Share",
    fill = "Permission"  ) +
  theme_minimal()

plot_bt19_permission_by_interruptor_party

party_levels <- c("SPD", "AfD", "FDP", "CDU/CSU", "DIE LINKE", "GRUENE")

plot_bt19_questions_asked <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    party = factor(interruptor_parliamentary_group, levels = party_levels)
  ) %>%
  filter(!is.na(party)) %>%
  count(party) %>%
  mutate(party = reorder(party, -n)) %>%
  ggplot(aes(x = party, y = n, fill = party)) +
  geom_col() +
  scale_fill_manual(values = party_colors, drop = FALSE) +
  labs(
    x = "Parliamentary group",
    y = "Number of parliamentary questions asked"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

plot_bt19_questions_asked

plot_bt19_questions_received <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    current_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    party = factor(current_parliamentary_group, levels = party_levels)
  ) %>%
  filter(!is.na(party)) %>%
  count(party) %>%
  mutate(party = reorder(party, -n)) %>%
  ggplot(aes(x = party, y = n, fill = party)) +
  geom_col() +
  scale_fill_manual(values = party_colors, drop = FALSE) +
  labs(
    x = "Parliamentary group",
    y = "Number of parliamentary questions received"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

plot_bt19_questions_received

plot_bt19_questions_asked_norm <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    party = interruptor_parliamentary_group,
    seats_bt19 = case_when(
      party == "AfD" ~ 94,
      party == "FDP" ~ 80,
      party == "CDU/CSU" ~ 246,
      party == "SPD" ~ 153,
      party == "GRUENE" ~ 67,
      party == "DIE LINKE" ~ 69,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(seats_bt19)) %>%
  count(party, seats_bt19) %>%
  mutate(
    questions_per_seat = n / seats_bt19,
    party = reorder(party, -questions_per_seat)
  ) %>%
  ggplot(aes(x = party, y = questions_per_seat, fill = party)) +
  geom_col() +
  scale_fill_manual(values = party_colors, drop = FALSE) +
  labs(
    x = "Parliamentary group",
    y = "Parliamentary questions asked per seat"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

plot_bt19_questions_asked_norm

plot_bt19_questions_received_norm <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    current_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    party = current_parliamentary_group,
    seats_bt19 = case_when(
      party == "AfD" ~ 94,
      party == "FDP" ~ 80,
      party == "CDU/CSU" ~ 246,
      party == "SPD" ~ 153,
      party == "GRUENE" ~ 67,
      party == "DIE LINKE" ~ 69,
      TRUE ~ NA_real_
    )
  ) %>%
  filter(!is.na(seats_bt19)) %>%
  count(party, seats_bt19) %>%
  mutate(
    questions_per_seat = n / seats_bt19,
    party = reorder(party, -questions_per_seat)
  ) %>%
  ggplot(aes(x = party, y = questions_per_seat, fill = party)) +
  geom_col() +
  scale_fill_manual(values = party_colors, drop = FALSE) +
  labs(
    x = "Parliamentary group",
    y = "Parliamentary questions received per seat"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

plot_bt19_questions_received_norm

cross_share <- df_plot %>%
  filter(
    !is.na(current_gender),
    current_gender != "no lookup",
    !is.na(interruptor_gender),
    interruptor_gender != "no lookup",
    !is.na(permission_granted)
  ) %>%
  mutate(
    permission = case_when(
      permission_granted == "True" ~ "Granted",
      permission_granted == "" ~ "Not granted",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(permission)) %>%
  count(current_gender, interruptor_gender, permission) %>%
  group_by(current_gender, interruptor_gender) %>%
  mutate(share = n / sum(n)) %>%
  ungroup()

cross_share

cross_share %>%
  filter(permission == "Granted") %>%
  ggplot(aes(x = interruptor_gender, y = current_gender, fill = share)) +
  geom_tile() +
  geom_text(aes(label = scales::percent(share, accuracy = 1)), size = 4) +
  scale_fill_gradient(low = "white", high = "darkgreen", limits = c(0, 1),
                      labels = scales::percent,
                      na.value = "white"  
  ) +
  labs(
    x = "Interruptor gender",
    y = "Addressed speaker gender",
    fill = "Share granted"
    ) +
  theme_minimal()

cross_share_19 <- df_plot %>%
  filter(
    BT %in% c("BT19","BT18","BT17","BT16"),
    !is.na(current_gender),
    current_gender != "no lookup",
    !is.na(interruptor_gender),
    interruptor_gender != "no lookup",
    !is.na(permission_granted)
  ) %>%
  mutate(
    permission = case_when(
      permission_granted == "True" ~ "Granted",
      permission_granted == "" ~ "Not granted",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(permission)) %>%
  count(current_gender, interruptor_gender, permission) %>%
  group_by(current_gender, interruptor_gender) %>%
  mutate(share = n / sum(n)) %>%
  ungroup()

cross_share_19

cross_share_19 %>%
  filter(permission == "Granted") %>%
  ggplot(aes(x = interruptor_gender, y = current_gender, fill = share)) +
  geom_tile() +
  geom_text(aes(label = scales::percent(share, accuracy = 1)), size = 4) +
  scale_fill_gradient(low = "white", high = "darkgreen", limits = c(0, 1),
                      labels = scales::percent,
                      na.value = "white"  
  ) +
  labs(
    x = "Interruptor gender",
    y = "Addressed speaker gender",
    fill = "Share granted"
  ) +
  theme_minimal()

cross_share_party <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    current_parliamentary_group != "fraktionslos",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    permission = case_when(
      permission_granted == "True" ~ "Granted",
      permission_granted == "" ~ "Not granted",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(permission)) %>%
  count(current_parliamentary_group, interruptor_parliamentary_group, permission) %>%
  group_by(current_parliamentary_group, interruptor_parliamentary_group) %>%
  mutate(share = n / sum(n)) %>%
  ungroup() %>%
  mutate(
    current_parliamentary_group = factor(
      current_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    ),
    interruptor_parliamentary_group = factor(
      interruptor_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    )
  )

cross_share_party %>%
  filter(permission == "Granted") %>%
  ggplot(aes(x = interruptor_parliamentary_group,
             y = current_parliamentary_group,
             fill = share)) +
  geom_tile(color = "white") +
  geom_text(
    aes(label = ifelse(is.na(share), "", scales::percent(share, accuracy = 1))),
    size = 4
  ) +
  scale_fill_gradient(
    low = "white",
    high = "darkgreen",
    limits = c(0, 1),
    labels = scales::percent,
    na.value = "white"  
  ) +
  labs(
    x = "Interruptor parliamentary group",
    y = "Addressed speaker parliamentary group",
    fill = "Share granted"
  ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank()
  )


cross_counts_party <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    current_parliamentary_group != "fraktionslos",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    current_parliamentary_group = factor(
      current_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    ),
    interruptor_parliamentary_group = factor(
      interruptor_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    ),
    seats_current = case_when(
      current_parliamentary_group == "AfD" ~ 94,
      current_parliamentary_group == "FDP" ~ 80,
      current_parliamentary_group == "CDU/CSU" ~ 246,
      current_parliamentary_group == "SPD" ~ 153,
      current_parliamentary_group == "GRUENE" ~ 67,
      current_parliamentary_group == "DIE LINKE" ~ 69,
      TRUE ~ NA_real_
    )
  ) %>%
  count(current_parliamentary_group, interruptor_parliamentary_group, seats_current) %>%
  mutate(
    count_per_seat = n / seats_current
  )

ggplot(
  cross_counts_party,
  aes(
    x = interruptor_parliamentary_group,
    y = current_parliamentary_group,
    fill = count_per_seat
  )
) +
  geom_tile(color = NA) +
  geom_text(aes(label = round(count_per_seat, 2)), size = 4) +
  scale_fill_gradient(
    low = "white",
    high = "darkblue",
    na.value = "white"
  ) +
  labs(
    x = "Interruptor parliamentary group",
    y = "Addressed speaker parliamentary group",
    fill = "Count / seats"
  ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank()
  )

library(dplyr)
library(tidyr)
library(ggplot2)

cross_party_ratio <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    current_parliamentary_group != "fraktionslos",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    current_parliamentary_group = factor(
      current_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    ),
    interruptor_parliamentary_group = factor(
      interruptor_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    )
  ) %>%
  count(current_parliamentary_group, interruptor_parliamentary_group, name = "observed") %>%
  complete(
    current_parliamentary_group,
    interruptor_parliamentary_group,
    fill = list(observed = 0)
  ) %>%
  group_by(interruptor_parliamentary_group) %>%
  mutate(row_total = sum(observed)) %>%
  ungroup() %>%
  group_by(current_parliamentary_group) %>%
  mutate(col_total = sum(observed)) %>%
  ungroup() %>%
  mutate(
    total = sum(observed),
    expected = (row_total * col_total) / total,
    ratio = ifelse(expected > 0, observed / expected, NA_real_)
  )

cross_party_ratio

ggplot(
  cross_party_ratio,
  aes(
    x = interruptor_parliamentary_group,
    y = current_parliamentary_group,
    fill = ratio
  )
) +
  geom_tile(color = NA) +
  geom_text(
    aes(label = ifelse(is.na(ratio), "", sprintf("%.2f", ratio))),
    size = 4
  ) +
  scale_fill_gradient2(
    low = "white",
    mid = "#deebf7",
    high = "#08519c",
    midpoint = 1,
    na.value = "white"
    ) +
  labs(
    x = "Interruptor parliamentary group",
    y = "Addressed speaker parliamentary group"
    ) +
  theme_minimal() +
  theme(
    panel.grid = element_blank(),
    legend.position = "none"
  )

library(dplyr)
library(tidyr)
library(igraph)
library(ggraph)
library(ggplot2)
library(grid)

edges <- df_plot %>%
  filter(
    BT == "BT19",
    !is.na(current_parliamentary_group),
    current_parliamentary_group != "",
    current_parliamentary_group != "no lookup",
    current_parliamentary_group != "fraktionslos",
    !is.na(interruptor_parliamentary_group),
    interruptor_parliamentary_group != "",
    interruptor_parliamentary_group != "no lookup",
    interruptor_parliamentary_group != "fraktionslos",
    !is.na(permission_granted)
  ) %>%
  mutate(
    current_parliamentary_group = factor(
      current_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    ),
    interruptor_parliamentary_group = factor(
      interruptor_parliamentary_group,
      levels = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
    )
  ) %>%
  count(interruptor_parliamentary_group, current_parliamentary_group, name = "observed") %>%
  complete(
    interruptor_parliamentary_group,
    current_parliamentary_group,
    fill = list(observed = 0)
  ) %>%
  group_by(interruptor_parliamentary_group) %>%
  mutate(row_total = sum(observed)) %>%
  ungroup() %>%
  group_by(current_parliamentary_group) %>%
  mutate(col_total = sum(observed)) %>%
  ungroup() %>%
  mutate(
    total = sum(observed),
    expected = (row_total * col_total) / total,
    ratio = ifelse(expected > 0, observed / expected, NA_real_),
    log_ratio = ifelse(ratio > 0, log(ratio), NA_real_)
  ) %>%
  filter(!is.na(log_ratio)) %>%
  mutate(
    weight_plot = abs(log_ratio),
    edge_type = case_when(
      ratio > 1 ~ "over",
      ratio < 1 ~ "under",
      TRUE ~ "neutral"
    )
  ) %>%
  filter(weight_plot > 0.15)

nodes <- tibble(
  name = c("AfD", "FDP", "CDU/CSU", "SPD", "GRUENE", "DIE LINKE")
)

graph <- graph_from_data_frame(
  d = edges %>%
    transmute(
      from = as.character(interruptor_parliamentary_group),
      to = as.character(current_parliamentary_group),
      ratio,
      log_ratio,
      weight_plot,
      edge_type
    ),
  vertices = nodes,
  directed = TRUE
)

set.seed(123)

ggraph(graph, layout = "circle") +
  geom_edge_link(
    aes(
      width = weight_plot,
      color = log_ratio
    ),
    alpha = 0.9,
    arrow = arrow(length = unit(3, "mm")),
    end_cap = circle(4, "mm")
  ) +
  geom_node_point(size = 8, color = "black") +
  geom_node_text(aes(label = name), size = 4, repel = FALSE, vjust = -1.3) +
  scale_edge_width(range = c(0.4, 2.5), guide = "none") +
  scale_edge_color_gradient2(
    low = "white",
    mid = "lightblue",
    high = "darkblue",
    midpoint = 0,
    name = "log(O/E)"
  ) +
  theme_void()

## regr

df_count <- df %>%
  group_by(interruptor_party, interruptor_position, current_gender, interruptor_gender, current_party, BT, current_position, current_gov, female_share_bt) %>%
  summarise(n_interruptions = n(), .groups = "drop")

model_pois <- glm(
  n_interruptions ~ current_gender + current_party + current_gov + BT,
  data = df_count,
  family = "poisson"
)

summary(model_pois)

summary(lm(n_interruptions ~ current_gender * current_gov + female_share_bt, data = df_count))
