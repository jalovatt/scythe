<section class="segment">

### Message.Msg(...) :id=message-msg

Prints arguments to the Reaper console. Each argument is sanitized with
`tostring`, and the string is ended by a line break.

| **Required** | []() | []() |
| --- | --- | --- |
| ... | any |  |

</section>
<section class="segment">

### Message.queueMsg(...) :id=message-queuemsg

Queues arguments for printing as a bulk message. This can be useful for scripts
with a lot of console output, as Reaper's performance can be impacted by printing
to the console too often. Arguments are sanitized with `tostring`.

| **Required** | []() | []() |
| --- | --- | --- |
| ... | any |  |

</section>
<section class="segment">

### Message.printQueue() :id=message-printqueue

Prints all stored messages and clears the queue

</section>