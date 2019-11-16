<section class="segment">

###  <a name="Message.Msg">Message.Msg(...)</a>

Prints arguments to the Reaper console. Each argument is sanitized with
`tostring`, and the string is ended by a line break.

| **Required** | []() | []() |
| --- | --- | --- |
| ... | any |  |

</section>
<section class="segment">

###  <a name="Message.queueMsg">Message.queueMsg(...)</a>

Queues arguments for printing as a bulk message. This can be useful for scripts
with a lot of console output, as Reaper's performance can be impacted by printing
to the console too often. Arguments are sanitized with `tostring`.

| **Required** | []() | []() |
| --- | --- | --- |
| ... | any |  |

</section>
<section class="segment">

###  <a name="Message.printQueue">Message.printQueue()</a>

Prints all stored messages and clears the queue

</section>