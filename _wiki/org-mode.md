# Org-mode

## Shortcuts

- `C-c a` show agenda
- `C-c C-t` rotate state (change TODO to DONE)
- `C-c C-s` schedule
- `C-c C-x p` set property (e.g. `STYLE` to `habit`)

For clock timing:

- `C-c C-x C-i`: start clock
- `C-c C-x C-o`: stop the clock
- `C-c C-x C-d`: display times
- `M-x org-resolve-clocks`

## Repeated tasks

[Documentation](https://orgmode.org/manual/Repeated-tasks.html).

Using a `+1m` says the date shift is exactly one month:

```org
** TODO Pay the rent
   DEADLINE: <2005-11-01 Tue +1m>
```

Using `++1w` shifts the date by at least one week, but also by as many
weeks as it takes to get this date into the future. However, it stays
on a Sunday, even if you called and marked it done on Saturday:

```org
** TODO Call Father
   DEADLINE: <2008-02-10 Sun ++1w>
```

Using `.+1m` will shift the date to one month after today:

``` org
** TODO Check the batteries in the smoke detectors
   DEADLINE: <2005-11-01 Tue .+1m>
```

## DEADLINE vs SCHEDULING

[Documentation](https://orgmode.org/manual/Deadlines-and-scheduling.html)

`DEADLINE`: 

- the task is supposed to be finished on that date
- the agenda for today will carry a warning about the approaching or missed deadline

`SCHEDULED`:

- you are planning to start working on that task on the given date
- a reminder that the scheduled date has passed will be present in the compilation for today, until the entry is marked DONE
