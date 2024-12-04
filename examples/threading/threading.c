#include "threading.h"
#include <unistd.h>
#include <stdlib.h>
#include <stdio.h>

// Optional: use these functions to add debug or error prints to your application
#define DEBUG_LOG(msg,...)
//#define DEBUG_LOG(msg,...) printf("threading: " msg "\n" , ##__VA_ARGS__)
#define ERROR_LOG(msg,...) printf("threading ERROR: " msg "\n" , ##__VA_ARGS__)

void* threadfunc(void* thread_param)
{

    // TODO: wait, obtain mutex, wait, release mutex as described by thread_data structure
    // hint: use a cast like the one below to obtain thread arguments from your parameter
    struct thread_data* thread_func_args = (struct thread_data *) thread_param;
    // sleep wait_to_obtain_ms
    const unsigned int wait_to_obtain_us = (unsigned int)thread_func_args->wait_to_obtain_ms * 1000;
    usleep(wait_to_obtain_us);
    // lock mutex
    if (pthread_mutex_lock(thread_func_args->mutex) != 0)
    {
        ERROR_LOG(" Could not lock mutex.");
        return NULL;
    }
    // sleep wait_to_release_ms
    const unsigned int wait_to_release_us = (unsigned int)thread_func_args->wait_to_release_ms * 1000;
    usleep(wait_to_release_us);
    // set thread_complete_success = true
    thread_func_args->thread_complete_success = true;
    //  release
    if (pthread_mutex_unlock(thread_func_args->mutex) != 0)
    {
      
        ERROR_LOG(" Could not unlock mutex.");
        return NULL;
    }
    return thread_param;
}


bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,int wait_to_obtain_ms, int wait_to_release_ms)
{
    /**
     * TODO: allocate memory for thread_data, setup mutex and wait arguments, pass thread_data to created thread
     * using threadfunc() as entry point.
     *
     * return true if successful.
     *
     * See implementation details in threading.h file comment block
     */
     // Allocate memory for thread_data
    struct thread_data *data = malloc(sizeof(struct thread_data));
    if (data == NULL) {
        perror("Failed to allocate memory for thread_data");
        return false;
    }

    // Initialize the thread_data structure
    data->mutex = mutex;
    data->wait_to_obtain_ms = wait_to_obtain_ms;
    data->wait_to_release_ms = wait_to_release_ms;
    data->thread_complete_success = false;

    // Create the thread
    if (pthread_create(thread, NULL, threadfunc, (void *)data) != 0) {
        perror("Failed to create thread");
        free(data);
        return false;
    }

    return true;
}

